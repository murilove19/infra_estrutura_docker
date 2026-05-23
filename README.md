# Persistência de Dados com Docker — Atividade Prática

## 1. Introdução

Quando você roda um container Docker, ele é **efêmero** — ou seja, tudo que você cria dentro dele some quando o container é removido. Isso é ótimo para aplicações stateless (sem estado), mas um problema sério para bancos de dados e aplicações que precisam guardar informações.

Para resolver isso, o Docker oferece dois mecanismos principais:

- **Named Volumes**: o Docker gerencia o armazenamento. Os dados ficam em uma área controlada pelo Docker e sobrevivem mesmo após a remoção do container.
- **Bind Mounts**: você aponta uma pasta do seu computador (host) diretamente para dentro do container. Qualquer arquivo criado lá aparece nos dois lados.

O objetivo desta atividade é entender na prática como esses mecanismos funcionam, além de aprender a fazer backup, restauração e automação de tarefas com scripts Bash.

---

## 2. Ambiente Utilizado

| Item | Versão |
|---|---|
| Sistema Operacional | Ubuntu 22.04.5 LTS (Jammy) |
| Docker Engine | 28.x |
| Docker Compose | v2.x |
| Git | 2.34.1 |
| CPU | 1 vCPU |
| RAM | 2 GB |
| Virtualização | VirtualBox |

### Verificação do ambiente

```bash
docker --version
docker compose version
git --version
docker run hello-world
```

---

## 3. Desenvolvimento da Atividade

### Cenário 1 — Persistência de Dados com MySQL e Named Volume

**Objetivo:** provar que dados inseridos num container MySQL continuam existindo mesmo depois que o container é destruído e recriado.

**Como funciona:** o Docker cria um volume nomeado (`mysql-prod-data`) que fica armazenado no host. O container usa esse volume para guardar os arquivos do banco. Quando removemos o container, o volume continua intacto. Ao recriar o container apontando para o mesmo volume, os dados voltam.

**Comandos executados:**

```bash
# 1. Criar o volume nomeado
docker volume create mysql-prod-data

# 2. Criar o container MySQL usando o volume
docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=senha123 \
  -e MYSQL_DATABASE=meubanco \
  -v mysql-prod-data:/var/lib/mysql \
  mysql:8.0

# 3. Verificar se o container está rodando
docker ps

# 4. Entrar no MySQL
docker exec -it mysql-prod mysql -uroot -psenha123

# 5. Dentro do MySQL: criar tabela e inserir dados
USE meubanco;

CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100)
);

INSERT INTO usuarios (nome, email) VALUES
  ('Ana Silva', 'ana@email.com'),
  ('Carlos Souza', 'carlos@email.com'),
  ('Maria Oliveira', 'maria@email.com');

SELECT * FROM usuarios;

exit

# 6. Remover o container (simulando destruição)
docker rm -f mysql-prod

# 7. Recriar o container com o mesmo volume
docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=senha123 \
  -e MYSQL_DATABASE=meubanco \
  -v mysql-prod-data:/var/lib/mysql \
  mysql:8.0

# 8. Validar que os dados persistiram
docker exec -it mysql-prod mysql -uroot -psenha123
USE meubanco;
SELECT * FROM usuarios;
```

**Resultado:** os 3 registros continuaram presentes após a remoção e recriação do container, confirmando a persistência do Named Volume.

**Evidências:** `screenshots/cenario1/`

---

### Cenário 2 — Backup e Restauração de Volume

**Objetivo:** aprender a fazer backup dos dados e restaurá-los em caso de perda total do volume.

**Como funciona:** usamos dois tipos de backup:
- `mysqldump`: exporta os dados do banco em formato SQL legível.
- `tar.gz`: compacta os arquivos binários do volume inteiro.

Para simular uma perda real, removemos o container **e** o volume. Depois restauramos o `.tar.gz` num volume novo e validamos que os dados voltaram.

**Comandos executados:**

```bash
# 1. Fazer dump SQL do banco
docker exec mysql-prod mysqldump -uroot -psenha123 meubanco \
  > ~/infra-persistencia-docker/backups/meubanco-backup.sql

# 2. Fazer backup compactado do volume inteiro
docker run --rm \
  -v mysql-prod-data:/data \
  -v ~/infra-persistencia-docker/backups:/backup \
  ubuntu tar czf /backup/mysql-prod-data.tar.gz -C /data .

# 3. Verificar arquivos gerados
ls -lh ~/infra-persistencia-docker/backups/

# 4. Simular perda: remover container e volume
docker rm -f mysql-prod
docker volume rm mysql-prod-data

# 5. Restaurar: recriar volume e restaurar backup
docker volume create mysql-prod-data

docker run --rm \
  -v mysql-prod-data:/data \
  -v ~/infra-persistencia-docker/backups:/backup \
  ubuntu tar xzf /backup/mysql-prod-data.tar.gz -C /data

# 6. Recriar o container
docker run -d \
  --name mysql-prod \
  -e MYSQL_ROOT_PASSWORD=senha123 \
  -e MYSQL_DATABASE=meubanco \
  -v mysql-prod-data:/var/lib/mysql \
  mysql:8.0

# 7. Validar restauração
docker exec -it mysql-prod mysql -uroot -psenha123 \
  -e "USE meubanco; SELECT * FROM usuarios;"
```

**Resultado:** após simular a perda total do volume e restaurar o backup `.tar.gz`, todos os dados voltaram corretamente.

**Evidências:** `screenshots/cenario2/` e `backups/`

---

### Cenário 3 — Bind Mount em Ambiente de Desenvolvimento

**Objetivo:** entender como o Bind Mount conecta uma pasta do host diretamente ao container em tempo real.

**Como funciona:** diferente do Named Volume (onde o Docker controla o armazenamento), no Bind Mount você escolhe exatamente qual pasta do host será espelhada dentro do container. Qualquer arquivo criado no host aparece instantaneamente dentro do container, e vice-versa. É muito usado em desenvolvimento para editar código no host e ver o resultado no container sem precisar reconstruir a imagem.

**Comandos executados:**

```bash
# 1. Criar diretório local no host
mkdir -p ~/infra-persistencia-docker/docker/bindmount-teste

# 2. Criar container com Bind Mount
docker run -d \
  --name container-bind \
  -v ~/infra-persistencia-docker/docker/bindmount-teste:/app \
  ubuntu sleep infinity

# 3. Criar arquivo no HOST
echo "Arquivo criado no HOST em $(date)" \
  > ~/infra-persistencia-docker/docker/bindmount-teste/arquivo-host.txt

# 4. Acessar o arquivo DENTRO do container
docker exec -it container-bind cat /app/arquivo-host.txt
```

**Resultado:** o arquivo criado no host apareceu imediatamente dentro do container no caminho `/app/arquivo-host.txt`, comprovando o espelhamento em tempo real do Bind Mount.

**Diferença entre host e container:**
- No host o arquivo está em: `~/infra-persistencia-docker/docker/bindmount-teste/arquivo-host.txt`
- No container o mesmo arquivo aparece em: `/app/arquivo-host.txt`

**Evidências:** `screenshots/cenario3/`

---

### Cenário 4 — Compartilhamento de Dados Entre Containers

**Objetivo:** demonstrar que múltiplos containers podem compartilhar o mesmo volume e se comunicar via arquivos.

**Como funciona:** criamos um volume compartilhado e dois containers usando esse mesmo volume. O container **produtor** escreve dados continuamente num arquivo de log. O container **consumidor** lê esse mesmo arquivo e exibe o conteúdo — mostrando que os dados foram compartilhados em tempo real entre os dois.

**Comandos executados:**

```bash
# 1. Criar volume compartilhado
docker volume create volume-compartilhado

# 2. Container produtor: escreve no arquivo a cada 3 segundos
docker run -d \
  --name container-produtor \
  -v volume-compartilhado:/dados \
  ubuntu sh -c "while true; do echo \"Dado gerado em \$(date)\" >> /dados/log.txt; sleep 3; done"

# 3. Aguardar ~10 segundos para acumular dados

# 4. Container consumidor: lê o arquivo gerado pelo produtor
docker run --rm \
  -v volume-compartilhado:/dados \
  ubuntu cat /dados/log.txt
```

**Resultado:** o container consumidor exibiu todas as linhas geradas pelo produtor, comprovando o compartilhamento de volume entre containers distintos.

**Evidências:** `screenshots/cenario4/`

---

### Cenário 5 — Automação de Backup com Script Bash

**Objetivo:** criar um script que automatize o processo de backup do banco de dados com nome baseado na data e hora.

**Como funciona:** o script realiza o `mysqldump` do banco, compacta o resultado em `.tar.gz` com o timestamp no nome e remove o `.sql` intermediário. Basta executá-lo sempre que quiser gerar um backup, ou agendá-lo via `cron` para rodar automaticamente.

**Script criado (`scripts/backup.sh`):**

```bash
#!/bin/bash

DATA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/infra-persistencia-docker/backups
CONTAINER="mysql-prod"
BANCO="meubanco"
SENHA="senha123"

echo "Iniciando backup em $DATA..."

mkdir -p $BACKUP_DIR

docker exec $CONTAINER mysqldump -uroot -p$SENHA $BANCO > $BACKUP_DIR/backup_$DATA.sql

tar czf $BACKUP_DIR/backup_$DATA.tar.gz -C $BACKUP_DIR backup_$DATA.sql

rm $BACKUP_DIR/backup_$DATA.sql

echo "Backup concluído: backup_$DATA.tar.gz"
ls -lh $BACKUP_DIR/
```

**Comandos executados:**

```bash
# Tornar o script executável
chmod +x ~/infra-persistencia-docker/scripts/backup.sh

# Executar o script
~/infra-persistencia-docker/scripts/backup.sh
```

**Resultado:** o script gerou automaticamente o arquivo `backup_20260523_112240.tar.gz` na pasta `backups/`, com o timestamp correto no nome.

**Evidências:** `screenshots/cenario5/` e `backups/`

---

## 4. Evidências

Todos os prints de execução estão organizados na pasta `screenshots/`, separados por cenário:

| Cenário | Print | Descrição |
|---|---|---|
| 1 | `Cenário 1 - Volume Criado.png` | Volume `mysql-prod-data` criado |
| 1 | `Cenário 1 - Dados Inseridos.png` | Tabela criada e 3 registros inseridos |
| 1 | `Cenário 1 - Dados Persistidos.png` | Dados presentes após remoção e recriação do container |
| 2 | `Cenário 2 - Dados Restaurados.png` | Dados recuperados após perda total do volume |
| 3 | `Cenário 3 - Bind Mount.png` | Arquivo do host acessível dentro do container |
| 4 | `Cenário 4 - Compartilhamento.png` | Container consumidor lendo dados do produtor |
| 5 | `Cenário 5 - Backup Automatizado.png` | Script gerando backup com timestamp |

---

## 5. Problemas Encontrados

### Problema 1 — Repositório GitHub com nome incorreto
**Descrição:** ao configurar o repositório remoto no Git, o nome digitado no comando foi diferente do nome real criado no GitHub (`infra-persistencia-docker` vs `infra_estrutura_docker`).

**Erro:**
```
fatal: repository 'https://github.com/murilove19/infra-persistencia-docker.git/' not found
```

**Solução:**
```bash
git remote remove origin
git remote add origin https://github.com/murilove19/infra_estrutura_docker.git
git push -u origin main
```

---

### Problema 2 — Pastas vazias não aparecem no GitHub
**Descrição:** as pastas `screenshots/cenario1` até `cenario5` foram criadas localmente mas não apareceram no GitHub porque o Git não versiona pastas vazias.

**Solução:** criar um arquivo `.gitkeep` dentro de cada pasta pelo próprio GitHub (Add file → Create new file), forçando o registro da pasta no repositório.

---

## 6. Conclusão

Esta atividade demonstrou na prática como o Docker trata o armazenamento de dados e as diferenças entre containers efêmeros e persistentes.

Os principais aprendizados foram:

- **Named Volumes** são a forma mais segura de persistir dados em produção — o Docker gerencia o armazenamento e os dados sobrevivem à remoção do container.
- **Bind Mounts** são ideais para desenvolvimento — permitem editar arquivos no host e ver o resultado imediatamente no container.
- **Backup e restauração** são essenciais em qualquer ambiente com dados importantes. O `mysqldump` exporta os dados de forma portável, enquanto o backup do volume garante recuperação completa.
- **Volumes compartilhados** permitem comunicação entre containers via sistema de arquivos, útil para arquiteturas de microsserviços.
- **Automação com Bash** reduz erros humanos e garante consistência nas operações de backup.

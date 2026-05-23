# Observações da Atividade

## 1. Comportamento do volume ao recriar o container
Durante o Cenário 1, foi possível observar que ao recriar o container com o mesmo volume, o MySQL identificou automaticamente os dados existentes sem necessidade de reconfiguração. Isso confirma que o volume funciona de forma completamente independente do ciclo de vida do container.

## 2. Diferença de tamanho entre os tipos de backup
No Cenário 2, o `mysqldump` gerou um arquivo `.sql` de 2,1KB (apenas os dados), enquanto o backup completo do volume via `tar.gz` resultou em 5,4MB (arquivos binários do MySQL). Para ambientes de produção, o `mysqldump` é mais portável e leve, enquanto o `tar.gz` garante recuperação total do estado do banco.

## 3. Bind Mount e permissões
No Cenário 3, o container rodou como root, o que evitou problemas de permissão no acesso aos arquivos do host. Em ambientes reais é importante mapear corretamente o usuário do container com o do host para evitar arquivos criados com permissões incorretas.

## 4. Volume compartilhado em tempo real
No Cenário 4, ficou evidente que o compartilhamento via volume é síncrono — os dados escritos pelo produtor apareceram imediatamente para o consumidor, sem necessidade de qualquer configuração de rede entre os containers.

## 5. Automação e timestamp
No Cenário 5, o uso de `$(date +%Y%m%d_%H%M%S)` no nome do arquivo garante que cada backup tenha um nome único, evitando sobrescrita acidental de backups anteriores.

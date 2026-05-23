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

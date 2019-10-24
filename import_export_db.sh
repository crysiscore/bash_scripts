#!/bin/bash

backup_dir=/opt/data/exportdb
script_exec_dir=/opt/data/
backup_files=$backup_dir/*
log_file=$backup_dir/log_restore.txt

MySQL_username='root'
MySQL_pass='password'


function rename_backup () {
   local file=$1
   rename 's/ /_/g' $file
}
function unzip_backup () {
   local file=$1
   echo "Unziping $file ..."
   unzip  $file
   if [ $? -eq 0 ]; then
       echo "File $file decompressed sucessfully"
       remove_white_spaces
   else
       echo "Error decompressing file $file ! It may be corrupted"
      log "Error decompressing file  $file ! It may be corrupted"
      return 1
  fi
}
function untar_backup () {
   local file=$1
   echo "Extracting tar archive $file ..."
   tar  -xzf  $file
   if [ $? -eq 0 ]; then
       echo "File $file decompressed sucessfully"
       remove_white_spaces
   else
       echo "Error decompressing file $file ! It may be corrupted"
       log "Error decompressing file  $file ! It may be corrupted"
       return 1
  fi
}
function import_database () {

   local file=$1
   local us_name=$2
   export_db_name="exp_$us_name"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "create database $export_db_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass $export_db_name < $file
   if [ $? -eq 0 ]; then
       echo "Backup   $file imported sucessfully"
   else
       echo "Error importing file $file into MySQL! It may be corrupted"
       log "Error importing file  $file  into MySQL!! It may be corrupted"
  fi
}
function log () {
   message=$1
   echo "$message" >> $log_file

}
function remove_white_spaces () {
# Remover espacos em branco nos nomes dos backups
cd $backup_dir
find -name "* *" -type f | rename 's/ /_/g'

}


remove_white_spaces

# Importar nome de US para array
# Add exception handling later
cd $backup_dir
declare -a us_names
readarray -t us_names < us_names.txt



## Para cada US verificar se existe o ficheiro export_db
## Caso nao,  saltar para o prox US


for us in "${us_names[@]}"
do
   # procurar o  backup da us
    curr_backup=$(find $backup_dir -type f -name "*$us*")
       # Se existir, fazer o restore no server
    if [ -n "$curr_backup" ]; then

        base_name=$(basename $curr_backup)
        echo "Backup da us $us encontrado: $base_name"
        extension="${base_name##*.}"
        filename="${base_name%.*}"
        echo $filename
        if [ "$extension" = "sql" ]; then
             echo "Importing $base_name into MySQL"
             import_database $base_name $us
        else
            echo "Unkown file type:$base_name... skiping file"
            log "Unkown file type: $base_name ... skiping file"
        fi
    else
        echo "Warning: Backup da us $us nao encontrado!!!"
        log "Warning: Backup da us $us nao encontrado!!!"
    fi
done

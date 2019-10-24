#!/bin/bash

backup_dir=/opt/data/expansao
script_exec_dir=/opt/data/
backup_files=$backup_dir/*
log_file=/opt/data/expansao/log_restore.txt

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
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "create database $us_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass $us_name < $file
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
cd  $script_exec_dir
declare -a us_names
readarray -t us_names < us_names.txt



## Para cada US verificar se existe o backup
## Caso nao,  saltar para o prox US
cd $backup_dir

for us in "${us_names[@]}"
do
   # procurar o  backup da us
    curr_backup=$(find $backup_dir -type f -name "*$us*")
       # Se existir, descomprimir e fazer o restore no server
    if [ -n "$curr_backup" ]; then

        base_name=$(basename $curr_backup)
        echo "Backup da us $us encontrado: $base_name"
        extension="${base_name##*.}"
        filename="${base_name%.*}"
        echo $filename
        if [ "$extension" = "zip" ]; then
            unzip_backup $base_name
               if [ $? -eq 0 ]; then
                    sql_file="${filename}.sql"
                    #ls -al $sql_file
                    echo "Importing $sql_file into MySQL"
                    import_database $sql_file $us
               else
                    echo "Error!!! Check mgs above!"
               fi
        elif [ "$extension" = "gz" ]; then
               untar_backup $base_name  
               if [ $? -eq 0 ]; then
                    temp_file="${filename%.*}"
                    sql_file="${temp_file}.sql"
                    #ls -al $sql_file
                    echo "Importing $sql_file into MySQL"
                    import_database $sql_file $us
                else
                    echo "Error!!! Check mgs above!"
               fi
        else
           echo "Unkown file type:$base_name... skiping file"
           log "Unkown file type: $base_name ... skiping file"
        fi
    else
        echo "Warning: Backup da us $us nao encontrado!!!"
        log "Warning: Backup da us $us nao encontrado!!!"
    fi
done

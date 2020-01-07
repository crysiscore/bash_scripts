#!/bin/bash

########################################################################################
# Recebe paramentro nome da us
# Verifica se existe o backup
# Se existir importa para MySQL caso contrario imprime erro



#################################################################
# Directorio onde ficam guardados os dumps
backup_dir=/home/administrator/openmrs/backups/Q12020
# Directorio onde fica este o script (backup_restore.sh)
script_exec_dir=/home/administrator/openmrs/backups
backup_files=$backup_dir/*
log_file=$script_exec_dir/log_restore.txt
us_names=$script_exec_dir/inh_us_names.txt
# Credenciais para acesso MySQL
MySQL_username='esaude'
MySQL_pass='esaude'

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
       rename 'y/A-Z/a-z/' *
       fix_wrong_file_names
        echo "All ok!"
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
       rename 'y/A-Z/a-z/' *
       fix_wrong_file_names
       echo "All ok!"
   else
       echo "Error decompressing file $file ! It may be corrupted"
       log "Error decompressing file  $file ! It may be corrupted"
       return 1
  fi
}

function import_database () {

   local file=$1
   local us_name=$2
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "drop database if exists $us_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "create database $us_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass $us_name < $file
   if [ $? -eq 0 ]; then
       log "Backup   $file imported sucessfully"
       echo "Backup   $file imported sucessfully"
         rm -f $file
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
#  Rename gaza  backups with wrong names 
function fix_wrong_file_names () {

   find $backup_dir -type f -name "*hrv*" | sed -e "p;s/hrv/vilanculos/" | xargs -n2 mv 

}

## Setting things up
cd $backup_dir

remove_white_spaces
#convert filenames in current directory to lowercase
rename 'y/A-Z/a-z/' *
#find . -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
fix_wrong_file_names

# Importar nome de US para array
# Add exception handling later
cd  $script_exec_dir
echo "" > $log_file



## Para cada US verificar se existe o backup
## Caso nao,  saltar para o prox US
cd $backup_dir


if [ $# -eq 0 ]
  then
    echo "No arguments suplied!! Deve fornecer o nome da us."
else
    
    for us in "$@"
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
                        log "Importing $sql_file into MySQL"
                        new_name="openmrs_inh_$us"
                        import_database $sql_file $new_name
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
                        log "Importing $sql_file into MySQL"
                        new_name="openmrs_inh_$us"
                        import_database $sql_file $new_name
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

fi
#!/bin/bash

########################################################################################
# Para executar este script e necessario ter uma lista dos nomes das US  que coinscide com
# o nome dos dumps num ficheiro de texto, disposto destda seguinte forma:
# Ficheiro ->  gz_us_names.txt
#zuza
#malhazine
#mocotuene
#chipadja
#  ...

#################################################################
# Directorio onde ficam guardados os dumps 
backup_dir=/home/administrator/bck/Q42019/Gaza
# Directorio onde fica este o script (gz_backup_restore.sh)
script_exec_dir=/home/administrator/bck/Q42019/
backup_files=$backup_dir/*
log_file=$backup_dir/log_restore.txt
us_names=$script_exec_dir/gz_us_names.txt
# Credenciais para acesso MySQL
MySQL_username='admin'
MySQL_pass='Op3nMRS'

 
#  Rename gaza  backups with wrong names 
function fix_wrong_file_names () {

   find $backup_dir -type f -name "*dumpxx*" | sed -e "p;s/dumpxx/csxaixai/" | xargs -n2 mv 
   find $backup_dir -type f -name "*mussabele*" | sed -e "p;s/mussabele/mussavelene/" | xargs -n2 mv 
   find $backup_dir -type f -name "*mubangoene*" | sed -e "p;s/mubangoene/mubanguene/" | xargs -n2 mv 
   find $backup_dir -type f -name "*chibabel*" | sed -e "p;s/chibabel/chibabelnovo/" | xargs -n2 mv  

   find $backup_dir -type f -name "*nhavaquene*" | sed -e "p;s/nhavaquene/nwavaquene/" | xargs -n2 mv 
   find $backup_dir -type f -name "*milenio*" | sed -e "p;s/milenio/vilamilenio/" | xargs -n2 mv 
   find $backup_dir -type f -name "*vlenine*" | sed -e "p;s/vlenine/vladmirlenine/" | xargs -n2 mv 
   find $backup_dir -type f -name "*mangul*" | sed -e "p;s/mangul/mangol/" | xargs -n2 mv  

   find $backup_dir -type f -name "*mangundze*" | sed -e "p;s/mangundze/mangunze/" | xargs -n2 mv 
   find $backup_dir -type f -name "*lawane*" | sed -e "p;s/lawane/tlawene/" | xargs -n2 mv 
   find $backup_dir -type f -name "*hpxx*" | sed -e "p;s/hpxx/hpxaixai/" | xargs -n2 mv 
   find $backup_dir -type f -name "*nhacutse*" | sed -e "p;s/nhacutse/nhancutse/" | xargs -n2 mv   

   find $backup_dir -type f -name "*lumumba*" | sed -e "p;s/lumumba/patricelumumba/" | xargs -n2 mv 
   find $backup_dir -type f -name "*jnherere*" | sed -e "p;s/jnherere/juliusnyerere/" | xargs -n2 mv 
   find $backup_dir -type f -name "*goabi*" | sed -e "p;s/goabi/marienngoabi/" | xargs -n2 mv 
   find $backup_dir -type f -name "*praiaxaixai*" | sed -e "p;s/praiaxaixai/praiaxx/" | xargs -n2 mv   

}

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

function unrar_backup () {
   local file=$1
   echo "Extracting rar  $file ..."
   unrar e  $file
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
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "drop database if exists $us_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass -e "create database $us_name ;"
   /usr/bin/mysql -u$MySQL_username -p$MySQL_pass $us_name < $file
   if [ $? -eq 0 ]; then
       echo "Backup   $file imported sucessfully"
       log "Backup   $file imported sucessfully"
       rm -f $file
   else
       echo "Error importing file $file into MySQL! It may be corrupted"
       log "Error importing file  $file  into MySQL!! It may be corrupted"
       rm -f $file
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


## Setting things up
cd $backup_dir
echo "" > log_restore.txt
remove_white_spaces
fix_wrong_file_names

# Importar nome de US para array
# Add exception handling later
cd  $script_exec_dir
declare -a us_names
readarray -t us_names < $us_names



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
                    log "Importing $sql_file into MySQL"
                    new_name="openmrs_gz_$us"
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
                     new_name="openmrs_gz_$us"
                     import_database $sql_file $new_name
                else
                    echo "Error!!! Check mgs above!"
               fi
        elif [ "$extension" = "rar" ]; then
               untar_backup $base_name  
               if [ $? -eq 0 ]; then
                    temp_file="${filename%.*}"
                    sql_file="${temp_file}.sql"
                    #ls -al $sql_file
                    echo "Importing $sql_file into MySQL"
                    log "Importing $sql_file into MySQL"
                     new_name="openmrs_gz_$us"
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

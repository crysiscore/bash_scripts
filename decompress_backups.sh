
#! /bin/bash

backup_dir=/home/administrator/openmrs/backups/junho/week1
files=$backup_dir/*

#Misc commands
#cd /home/asamuel/epts/openmrs/backups/$region/
#find . -name "*.gz.enc" -exec rename -v 's/\.gz.enc$/\.gz/i' {} \;
#find . -name "*.tar.enc" -exec rename -v 's/\.enc$/\.gz/i' {} \;
#find . -name "*tar.gz" -exec tar -xzf {} \; 

echo "" > log_file

cd $backup_dir

for file in $files

   do
        f=$(basename "$file")
        ext="${f##*.}"
        echo processing $f
        #echo extension of $f   is $ext
        #sleep 2
       if [ "$ext" = "gz" ];
            then
              echo "************************************************************************************"
              echo extension of $f   is $ext 
              tar -xzf  "$f" || echo "error! Failed to decompress (tar) $f" 2>&1  $log_file
       else
           if [ "$ext" = "zip" ];
              then
                echo "************************************************************************************<s"
                echo extension of $f   is $ext 
                unzip "$f" || echo "error! Failed to unzip $f " 2>&1 $log_file

           else
                 echo error! file $f is not an valid extension 2>&1 $log_file
          fi

       fi

  done






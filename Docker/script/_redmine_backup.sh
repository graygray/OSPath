
redDir_Postgres="/home/gray.lin/redmine/postgresql-data"
redDir_Files="/home/gray.lin/redmine/files"
backupDir="/mnt/disk2/backups/redmine"

cd $backupDir

# TODAY=$(date +"%Y%m%d_%I%M%S")
TODAY=$(date +"%Y%m%d_%I%M")
echo $TODAY
# rm -r $TODAY
mkdir $TODAY
chmod 777 $TODAY
cd $TODAY

# backup DB ================================================================================
docker exec postgres pg_dump -U redmine -d redmine -Fc --file=/var/lib/postgresql/data/redmine.sqlc
cp $redDir_Postgres/redmine.sqlc .

# backup files folder ================================================================================
# sudo chmod 777 $redDir_Files/
tar -zcvf redmineFiles.tar.gz $redDir_Files/*

# make all file in backupDir accessable
chmod 777 *

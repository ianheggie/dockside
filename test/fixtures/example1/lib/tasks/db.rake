namespace :db do
  task backup: [:environment] do
    system "mysqldump my_database > tmp/backup_file.sql"
  end
end
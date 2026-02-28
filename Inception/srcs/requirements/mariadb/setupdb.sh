
#!/bin/bash

mysqld_safe &


while ! /usr/bin/mysqladmin ping -h 'localhost' --silent; do
    echo "waiting for database ..."
    sleep 1
done


echo "$MYSQL_ROOT_PASSWORD, $MYSQL_ADMIN_USER, $MYSQL_ADMIN_PASSWORD, $MYSQL_USER, $MYSQL_PASSWORD"

ROOT_INSECURE=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e ";" 2>&1| grep 'Access denied for user' > /dev/null; echo "$?")

if [ $ROOT_INSECURE -ne 0 ]; then
    echo "Setting Root and admin"
    QUERY1="
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');
        DROP DATABASE IF EXISTS test;
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
        FLUSH PRIVILEGES;
        SELECT USER,HOST,PASSWORD PLUGIN FROM mysql.user;"
    
    mysql -u root -e "$QUERY1"
    echo $?
    echo "mysql -u root -e $QUERY1"
fi

DB_EXISTS=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES LIKE 'wordpress';" | grep "wordpress" > /dev/null; echo "$?")
if [ $DB_EXISTS -ne 0 ]; then
    echo "Creating database..."
    QUERY2="CREATE DATABASE wordpress;
    CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER
    ON wordpress.*
    TO '$MYSQL_USER'@'%';
    CREATE USER IF NOT EXISTS '$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';
    GRANT SELECT,INSERT,UPDATE,DELETE,DROP,ALTER ON *.* TO '$MYSQL_ADMIN_USER'@'%' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
    SELECT USER,HOST,PASSWORD PLUGIN FROM mysql.user;"
    mysql -u root -p$MYSQL_ROOT_PASSWORD -e "$QUERY2"
    echo $?
    echo "mysql -u root -p$MYSQL_ROOT_PASSWORD -e $QUERY2"
fi







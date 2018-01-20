#!/bin/bash
set -e

function init_mysql()
{   
    bootfile=$1
    echo "[Mysql] secure installation"
    echo "USE mysql;" > $bootfile;
    echo "UPDATE user SET password=PASSWORD('') WHERE User='root' AND host='localhost';" >> $bootfile
    echo "DELETE FROM user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> $bootfile
    echo "DELETE FROM user WHERE User='';" >> $bootfile
    echo "DELETE FROM db WHERE Db LIKE 'test%';" >> $bootfile
    echo "DROP DATABASE test;" >> $bootfile

    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        echo "[Mysql] updating root password"
        echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;" >> $bootfile
    fi

    # MYSQL_USER: "username:password" or "username". password will be the same as username if omitted.
    # For multiple user creation, seperate them with ";".
    if [ -n "$MYSQL_USER" ]; then
        IFS=';'; users=($MYSQL_USER); unset IFS;
        for entry in "${users[@]}"; do
            IFS=':'; sub=($entry); unset IFS;
            if [ ${#sub[@]} -eq 1 ]; then
                username=${sub[0]}
                password=$username
            elif [ ${#sub[@]} -eq 2 ]; then
                username=${sub[0]}
                password=${sub[1]}
            else
                echo "[Mysql] invalid username in ${MYSQL_USER}"
                exit 1
            fi
            echo "[Mysql] create user ${username}"
            echo "CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${password}';" >> $bootfile
        done
    fi

    # MYSQL_DATABASE: "username@database" or "database". username will be the same as database if omitted.
    # User will be created(with password the same as username) if not exist.
    # For multiple database creation, seperate them with ";".
    if [ -n "$MYSQL_DATABASE" ]; then
        IFS=';'; ary=($MYSQL_DATABASE); unset IFS;
        for entry in "${ary[@]}"; do
            IFS='@'; sub=($entry); unset IFS;
            if [ ${#sub[@]} -eq 1 ]; then
                username=${sub[0]}
                database=$username
            elif [ ${#sub[@]} -eq 2 ]; then
                username=${sub[0]}
                database=${sub[1]}
            else
                echo "[Mysql] invalid database in ${MYSQL_DATABASE}"
                exit 1
            fi
            echo "[Mysql] create database ${database}"
            echo "CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $bootfile
            # ensure user exists
            echo "CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${username}';" >> $bootfile
            echo "[Mysql] grant privileges to ${username} on ${database}"
            echo "GRANT ALL PRIVILEGES ON \`${database}\`.* to '${username}'@'%';" >> $bootfile
        done
    fi

    echo "FLUSH PRIVILEGES;" >> $bootfile
}

args=()

if [ ! -d "/var/run/mysqld" ]; then
    mkdir -p /var/run/mysqld
    chown -R mysql:mysql /var/run/mysqld
    if [ -n "$MYSQL_TIMEZONE" ]; then
        echo "[Mysql] setting timezone to $MYSQL_TIMEZONE"
        sed -i -re "s/(^default-time-zone\s*=\s*')[^']+('$)/\1$MYSQL_TIMEZONE\2/g" /etc/mysql/my.cnf
    fi
    if [ -n "$MYSQL_MODE" ]; then
        echo "[Mysql] setting sql mode to $MYSQL_MODE"
        sed -i -re "s/(^sql_mode\s*=\s*\")[^\"]+(\"$)/\1$MYSQL_MODE\2/g" /etc/mysql/my.cnf
    fi
    mysql_install_db
    if [ -z "$MYSQL_SKIP_INIT" ]; then
        tfile=`mktemp`
        chown mysql:mysql $tfile
        init_mysql "$tfile"
        args+=("--init-file=$tfile")
        echo "[Mysql] initializing from $tfile"
    fi
fi

exec "$@" "${args[@]}"


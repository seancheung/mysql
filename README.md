# mysql
Mysql(5.7) docker image with convenient initialization.

## Run

```bash
docker run -d -p 3306:3306 -e "MYSQL_ROOT_PASSWORD=rootpassword" -e "MYSQL_USER=mypass:myuser" -e "MYSQL_DATABASE=myuser@mydb" seancheung/mysql:5.7
```

## Environment variables


**MYSQL_ROOT_PASSWORD**

Password for `root@%`. Note that user `root@localhost` has no password.

If this variable is not set, `root@%` will not be created, thus *root access is not allowed from outside the container*.


**MYSQL_USER**

Users to create at initialization step. It can be in the following formats:

- `username:password` Username with password
- `username` Password will be the same as username

For multiple users creation, seperate entries with `;`.

e.g. `username1;username2:password2;username3`


**MYSQL_DATABASE**

Databases to create at initialization step. It can be in the following formats:

- `username@database` Database with username
- `database` Username will be the same as database

> If a user does not exist already, it will be created with the password being the same as its name.

For multiple database creation, seperate entries with `;`.

e.g. `database1;username@database2;username@database3`


**MYSQL_MODE**

Update mysql_mode in /etc/mysql/my.cnf

e.g. `STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER`


**MYSQL_TIMEZONE**

Set default timezone in /etc/mysql/my.cnf

e.g. `+08:00`


**MYSQL_SKIP_INIT**

If this variable is set(not empty), Initialization will be skipped.

For manually initialization, you may run 

```bash
docker exec -it <container_name> mysqladmin -u root password 'new-password'
```

 or 

 ```bash
 docker exec -it <contrainer_name> mysql_secure_installation
 ```

 ## CLI Client

```bash
docker exec -it <contrainer_name> mysql
docker exec -it <contrainer_name> mysql -u myuser -p
```
#!/bin/bash
#
# MISP docker startup script
# Xavier Mertens <xavier@rootshell.be>
# Steven Goossens <steven@teamg.be>
#
# 2017/05/17 - Created
# 2017/05/31 - Fixed small errors
# 2019/10/17 - Use built-in mysql docker DB creation and use std env names (dafal)
# 2021/03/09 - Update to work with the install script provided by MISP. Includes https support, Python venv,...
#

set -e

if [ -r /.firstboot.tmp ]; then
        echo "Creating MySQL database"
        # Check MYSQL_HOST
        if [ -z "$MYSQL_HOST" ]; then
                echo "MYSQL_HOST is not set. Aborting."
                exit 1
        fi
		
		# Waiting for DB to be ready
		while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
		    sleep 5
			echo "Waiting for database to be ready..."
		done
		
        # Set MYSQL_PASSWORD
        if [ -z "$MYSQL_PASSWORD" ]; then
                echo "MYSQL_PASSWORD is not set, use default value 'misp'"
                MYSQL_PASSWORD=misp
        else
                echo "MYSQL_PASSWORD is set to '$MYSQL_PASSWORD'"
        fi

        ret=`echo 'SHOW TABLES;' | mysql -u $MYSQL_USER --password="$MYSQL_PASSWORD" -h $MYSQL_HOST -P 3306 $MYSQL_DATABASE # 2>&1`
        if [ $? -eq 0 ]; then
                echo "Connected to database successfully!"
                found=0
                for table in $ret; do
                        if [ "$table" == "attributes" ]; then
                                found=1
                        fi
                done
                if [ $found -eq 1 ]; then
                        echo "Database misp available"
                else
                        echo "Database misp empty, creating tables ..."
                        ret=`mysql -u $MYSQL_USER --password="$MYSQL_PASSWORD" $MYSQL_DATABASE -h $MYSQL_HOST -P 3306 2>&1 < /var/www/MISP/INSTALL/MYSQL.sql`
                        if [ $? -eq 0 ]; then
                            echo "Imported /var/www/MISP/INSTALL/MYSQL.sql successfully"
                        else
                            echo "ERROR: Importing /var/www/MISP/INSTALL/MYSQL.sql failed:"
                            echo $ret
                        fi
                fi
        else
                echo "ERROR: Connecting to database failed:"
                echo $ret
        fi

        # MISP configuration
        echo "Creating MISP configuration files"
        cd /var/www/MISP/app/Config
	cp -a database.default.php database.php
        sed -i "s/'database' => 'misp'/'database' => '$MYSQL_DATABASE'/" database.php
	sed -i "s/localhost/$MYSQL_HOST/" database.php
        sed -i "s/db\s*login/$MYSQL_USER/" database.php
        sed -i "s/8889/3306/" database.php
        sed -i "s/db\s*password/$MYSQL_PASSWORD/" database.php

        # Fix the base url
        if [ -z "$MISP_BASEURL" ]; then
                echo "No base URL defined, don't forget to define it manually!"
        else
                echo "Fixing the MISP base URL ($MISP_BASEURL) ..."
                sed -i "s@'baseurl'[\t ]*=>[\t ]*'.*',@'baseurl' => '$MISP_BASEURL',@g" /var/www/MISP/app/Config/config.php
                sed -i "s@'rest_client_baseurl'[\t ]*=>[\t ]*'.*',@'rest_client_baseurl' => '$MISP_BASEURL',@g" /var/www/MISP/app/Config/config.php
        fi
		
		#Redis should not run as a daemon
	sed -i "s/daemonize yes/daemonize no/g" /etc/redis/redis.conf
	service cron start
	
	##Schedule to sync all servers every hour
	{ crontab -l 2>/dev/null || true; echo "0 * * * * /var/www/MISP/app/Console/cake Server pullAll 2 full"; } | crontab -
	
	##Schedule to fetch all feeds at 1 am
	{ crontab -l 2>/dev/null || true; echo "0 1 * * * /var/www/MISP/app/Console/cake Server fetchFeed 2 all"; } | crontab -
        rm -f /.firstboot.tmp
fi

# Make MISP live - this isn't ideal, as it means taking an instance
# non-live will make it live again if the container restarts.  That seems
# better than the default which is that MISP is non-live on container restart.
# Ideally live/non-live would be persisted in the database.
/var/www/MISP/app/Console/cake Admin setSetting "MISP.python_bin" "/var/www/MISP/venv/bin/python"
/var/www/MISP/app/Console/cake live 1
chown www-data:www-data /var/www/MISP/app/Config/config.php*

# Start supervisord
echo "Starting supervisord"
cd /
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
          

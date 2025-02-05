#! /bin/sh


if [ ! -f /.configured ] ; then
	# configure port with environment var DBHOST
	sed -i "s/[$]dbhost = [']localhost[']/\$dbhost = '$DBHOST'/" /var/www/dcim/db.inc.php
	sed -i "s/[$]dbname = [']dcim[']/\$dbname = '$DCIM_DB_SCHEMA'/" /var/www/dcim/db.inc.php
	sed -i "s/[$]dbuser = [']dcim[']/\$dbuser = '$DCIM_DB_USER'/" /var/www/dcim/db.inc.php
	sed -i "s/[$]dbpass = [']dcim[']/\$dbpass = '$DCIM_DB_PASSWD'/" /var/www/dcim/db.inc.php

	if [ -f "$SSL_CERT_FILE" ] && [ -f "$SSL_KEY_FILE" ] ; then
		a2enmod ssl
		a2ensite default-ssl
		cd /etc/ssl/certs/
		cp $SSL_CERT_FILE ssl-cert.pem
		cp $SSL_KEY_FILE ssl-cert.key
	fi

	# for swarm secret
	if [ -f "$DCIM_PASSWD_FILE" ] ; then
		PASSWORD=$(cat $DCIM_PASSWD_FILE)
	elif [ ! -z "$DCIM_PASSWD" ] ; then
		PASSWORD=$DCIM_PASSWD
	else
		PASSWORD=dcim
	fi

	# Fix: if there is already modified opendcim.password, then do 
	# not touch it, if not then create it with the default user/password
	if [ ! -f /data/opendcim.password ] ; then
	    htpasswd -cb /data/opendcim.password dcim $PASSWORD
	fi

	cd /var/www/dcim
	for D in images pictures drawings ; do
		if [ ! -d /data/$D ] ; then
			mkdir /data/$D
		fi
		# tohle je spatne, udela je to jen pokud existuji
		# ale ty images a drawings tam teprve nakopiruji
		# zvenci, tazke tam na zacatku nejsou a kvuli tomuhle se ani nevytvori linky.
		if [ -d /var/www/dcim/$D ] ; then
			mv /var/www/dcim/$D/* /data/$D
			rm -rf /var/www/dcim/$D
			ln -s /data/$D .
		fi
		ln -s /data/pictures .
		ln -s /data/drawings .
		
		chown www-data:www-data /data/$D
	done

	# fix permissions on images directory
	chmod 555 /data/images
	chown www-data:www-data /var/www/dcim/vendor/mpdf/mpdf/ttfonts

	touch /.configured
fi

for param in "$@" ; do
	if [ "$param" = "--remove-install" ] ; then 
		rm -f /var/www/dcim/install.php
	elif [ "$param" = "--enable-ldap" ] ; then
		mv /var/www/dcim/.htaccess /var/www/dcim/.htaccess.no
		sed -i "s/Apache/LDAP/" /var/www/dcim/db.inc.php
	fi
done

exec docker-php-entrypoint -DFOREGROUND

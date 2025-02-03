FROM php:8.4.3-apache
# https://github.com/opendcim/openDCIM/archive/refs/tags/23.04.tar.gz 
# https://github.com/opendcim/openDCIM/archive/23.04.tar.gz 
# ARG OPENDCIMPATH=https://github.com/samilliken/openDCIM/archive/
ARG OPENDCIMPATH=https://github.com/opendcim/openDCIM/archive/
ARG VER=23.04
ARG OPENDCIMFILE=$VER.tar.gz
RUN sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && apt-get install -y -q --no-install-recommends \ 
    	    snmp \ 
    	    snmp-mibs-downloader \ 
    	    graphviz \ 
    	    libsnmp-dev \ 
    	    libpng-dev \ 
    	    libjpeg-dev \ 
    	    locales \ 
    	    libldap2-dev \
	    libzip-dev 

#     See https://serverfault.com/questions/633394/php-configure-not-finding-ldap-header-libraries
#    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
#    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
RUN docker-php-ext-install pdo pdo_mysql gettext snmp gd zip ldap \
    && mkdir -p /var/www && cd /var/www \
    && wget -q $OPENDCIMPATH/$OPENDCIMFILE \
    && tar xzf $OPENDCIMFILE \
    && rm -f $OPENDCIMFILE \
    && mv /var/www/openDCIM-$VER /var/www/dcim \
    && cp /var/www/dcim/db.inc.php-dist /var/www/dcim/db.inc.php 

#-----------

#FROM php:8.4.3-apache

#LABEL mantainer="jan.kreps@cvut.cz"

# COPY --from=0 /var/www/dcim /var/www/dcim
# COPY --from=0 /usr/local /usr/local

# configuration for apache
COPY apache2.conf /etc/apache2/apache2.conf

# enable localization, see locale-gen below
COPY locale.gen /etc

# RUN sed -i 's/jessie\/updates main/jessie\/updates main contrib non-free/' /etc/apt/sources.list \
#     && sed -i 's/jessie main/jessie main contrib non-free/' /etc/apt/sources.list \
#     && apt update && apt install -y -q --no-install-recommends \
# 	    snmp \
# 	    snmp-mibs-downloader \
# 	    graphviz \
# 	    libsnmp-base libsnmp30 \
# 	    libpng12-0 \
# 	    libjpeg62-turbo \
# 	    locales \
#     && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
#     && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
RUN a2enmod rewrite

# # disable error printing to avoid redirection failure when installing
RUN echo "display_errors = Off"  | tee /usr/local/etc/php/php.ini

COPY dcim.htaccess /var/www/dcim/.htaccess
COPY 000-default.conf /etc/apache2/sites-available
COPY default-ssl.conf /etc/apache2/sites-available

# apply patch for broken redirection when running on non standard ports
COPY patches/misc.inc.php /var/www/dcim/

# declaration of volumes 
VOLUME ["/data"]

# init script as entrypoint for initial configuration
COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]


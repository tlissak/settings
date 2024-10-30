#!/bin/bash

installPHP() {

	echo $PHPVER

	# PHP and common Modules
	msg_info "Installing PHP"

	read -e -p "PHP Version:" -i "8.0" PHPVER

	#echo $PHPVER

	apt-get -qy install php$PHPVER php-common libapache2-mod-php
	msg_ok "PHP installed"

	msg_info "Installing common Modules.. "
	apt-get -qy install php-curl php-dom php-ftp php-pdo php-pdo-mysql php-fileinfo php-simplexml php-imap php-dev php-gd php-imagick php-intl php-ps php-json php-mbstring php-mysql php-pear php-pspell php-xml php-zip php-xsl php-mcrypt php-soap
	#dpkg --configure -a
	#dpkg --remove --force-remove-reinstreq gsfonts
	msg_ok "common Modules installed"
}


installPhpVersion() {

    if [ -n "$1" ]; 
        then PHPVER=$1; 
        else read -e -p "PHP Version:" -i "8.0" PHPVER; 
    fi


    php -v > /dev/null 2>&1
    PHP_INSTALLED_VER=$?
    if [[ $PHP_INSTALLED_VER -ne 0 ]]; then
        msg_info 'Php is not installed'
    else
        msg_ok "PHP is already installed "
        php -v
        return   
    fi


	apt-get -qqy install apt-transport-https lsb-release ca-certificates wget
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg 
	sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
	apt-get -qqy update

	
	#php manual selection 
	#update-alternatives --config php

    
	update-alternatives --set php /usr/bin/php$PHPVER 
	update-alternatives --set phar /usr/bin/phar$PHPVER 
	update-alternatives --set phar.phar /usr/bin/phar.phar$PHPVER 

	#update-alternatives --set phpize /usr/bin/phpize$PHPVER
	#update-alternatives --set php-config /usr/bin/php-config$PHPVER


	

	
}


installPHPExtentions(){
	apt-get -qqy install php$PHPVER php$PHPVER-common
	apt-get -qqy install php$PHPVER-fileinfo php$PHPVER-pdo-sqlite php$PHPVER-ftp php$PHPVER-soap php$PHPVER-imap php-fpm php$PHPVER-intl php$PHPVER-json php$PHPVER-mysql php$PHPVER-pdo-mysql php$PHPVER-zip php$PHPVER-gd php$PHPVER-mbstring php$PHPVER-curl php$PHPVER-xml 

}

installComposer() {
	
	#https://getcomposer.org/doc/00-intro.md


    /usr/local/bin/composer -v > /dev/null 2>&1
    COMPOSER=$?
    if [[ $COMPOSER -ne 0 ]]; then
        msg_info 'Composer is not installed'
    else
        msg_ok 'Composer is already installed'
        return        
    fi


	msg_info "Install php composer"
	EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

	if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
	then
		msg_error 'ERROR: Invalid installer checksum'
		rm composer-setup.php
		return
	fi

	#Install Globaly 
	#mv composer.phar /usr/local/bin/composer

	#install Localy
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	#Usage : php bin/composer

	rm composer-setup.php
	#rm composer.phar
}


installComposerM1() {
	# Install Composer
	msg_info  "Install composer .. "
	wget -O composer-setup.php https://getcomposer.org/installer
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	chown -R $USER ~/.composer/
	composer update --ignore-platform-reqs
	
	#if composer update failed with
	#file_put_contents(./composer.lock): Failed to open stream: Permission denied
	#do :
	#chmod 0777 ./composer.lock
}

cpPhpConfigForce(){
	PHPVER=8.0
	output=/etc/php/$PHPVER/apache2/conf.d/php.ini
	cp php.ini $output
	output=/etc/php/$PHPVER/cli/conf.d/php.ini
	cp php.ini $output
}

cpPhpConfig(){
	
	output=/etc/php/$PHPVER/apache2/conf.d/php.ini

	if [ ! -f $output ]; then
		msg_info "Move php.ini to config path"
		cp php.ini $output
		msg_ok "Php.ini moved to config path"	
	else
		msg_info "File ${output} already Exist"		
	fi	


	output=/etc/php/$PHPVER/cli/conf.d/php.ini

	if [ ! -f $output ]; then
		msg_info "Move php.ini to CLI config path"
		cp php.ini $output
		msg_ok "Php.ini moved to CLI config path"	
	else
		msg_info "File ${output} already Exist"		
	fi	
}

editPhpConfig(){

	
	input="/etc/php/$PHPVER/apache2/php.ini"
	output="/etc/php/$PHPVER/apache2/php-MODIFIED.ini"


	if [ ! -f $output ]; then
		msg_info "File not found!"
	else
		msg_info "File ${output} already Exist"
		return
	fi


	sed $input -e "2s/^/\n;;;;;;;;;;;;;;;;;;;\n; MODIFIED BY SCRIPT ;\n;;;;;;;;;;;;;;;;;;;\n/" \
	| sed  -e "s/display_errors = Off/display_errors = On/"  \
	| sed -e "s/display_startup_errors = Off/display_startup_errors = On/"  \
	| sed -e "s/short_open_tag = Off/short_open_tag = On/"  \
	| sed -e "s/;max_input_vars = 1000/max_input_vars = 20000/"  \
	| sed -e "s/expose_php = On/expose_php = Off/"  \
	| sed -e "s/post_max_size = 8M/post_max_size = 500M/"  \
	| sed -e "s/upload_max_filesize = 2M/upload_max_filesize = 1000M/"  \
	| sed -e "s/;date.timezone =/date.timezone = Europe\/Paris/"  \
	> $output


}
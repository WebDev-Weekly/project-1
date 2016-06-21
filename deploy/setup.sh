ENV=$1

# set install path
SITENAME=todolist.com
INSTALLDIR=/website/${SITENAME}

# return 1 if global command line program installed, else 0
function program_is_installed {
	# set to 1 initially
	local return_=1
	# set to 0 if not found
	type $1 >/dev/null 2>&1 || { local return_=0; }

	echo "$return_"
}

echo " "
echo "#######################"
echo "### Create logs dir ###"
echo "#######################"

# Create the Logs dir
echo "Create logs directory."
mkdir -p ${INSTALLDIR}/logs

if [ -d ${INSTALLDIR}/logs ]; then
	chmod -R 777 ${INSTALLDIR}/logs
fi

echo " "
echo "###############################"
echo "### Update and Install Packages ###"
echo "###############################"

apt-get update

# Install the packages
export DEBIAN_FRONTEND=noninteractive
apt-get install -y php5 php5-cli apache2 git curl mysql-server mysql-client php5-mysql vim libapache2-mod-php5 php5-curl

# Composer
echo " "
echo "########################"
echo "### Composer ###"
echo "########################"

if [ -f /usr/local/bin/composer ]; then
	echo "Composer already installed. Checking for library updates..."
	composer self-update
else
	echo "Installing composer..."
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer
fi

# Change to the installation directory so Composer knows
# where to install the packages.
cd ${INSTALLDIR}
composer install

# Bower
echo " "
echo "#####################"
echo "### Bower install ###"
echo "#####################"

if [ $(program_is_installed bower) == 1 ]; then
	echo "bower is already installed."
else
	echo "bower is not yet installed. Installing..."
	apt-get install -y python-software-properties python g++ make
	add-apt-repository ppa:chris-lea/node.js
	apt-get update
	apt-get install -y nodejs
	apt-get autoremove
	npm install -g bower
fi

# Change to the installation directory so Bower knows
# where to install the libraries.
echo "Installing bower components"
cd ${INSTALLDIR}
bower --allow-root install

# MySQL DB Configuration and Setup
echo " "
echo "########################"
echo "### Run Initial SQL file ###"
echo "########################"

if [ -f ${INSTALLDIR}/deploy/init.sql ]; then

    #We're not on production yet, so install the DB
	if [ ${ENV} != 'prod' ]; then
		mysql < ${INSTALLDIR}/deploy/init.sql
	fi
fi

### Apache
echo " "
echo "######################"
echo "### Apache install ###"
echo "######################"

# display all PHP errors
sed -i "s/display_errors = Off/display_errors = On/g" /etc/php5/apache2/php.ini

cp ${INSTALLDIR}/deploy/httpd.conf /etc/apache2/sites-available/${SITENAME}.conf
sed -i "s/sitename/${SITENAME}/g" /etc/apache2/sites-available/${SITENAME}.conf
a2dissite 000-default.conf
a2ensite ${SITENAME}
a2enmod rewrite
a2enmod expires

# Restart Apache to ensure all services are running and things are properly installed
service apache2 restart
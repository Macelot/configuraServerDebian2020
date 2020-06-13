#salvar este arquivo 
#wget 
#executar
#https://www.digitalocean.com/community/tutorials/how-to-install-phpmyadmin-from-source-debian-10#conclusion
su root
apt-get install build-essential
apt-get install linux-headers-$(uname -r)
mkdir vbox
cp /media/cdrom0/VBoxLinuxAdditions.run  /home/marcelot/vbox
cd vbox
./VBoxLinuxAdditions.run
#halt

#configurando SSH
echo PermitRootLogin yes >> /etc/ssh/sshd_config
echo PubKeyAuthentication yes >> /etc/ssh/sshd_config
echo AuthorizedKeysFile >> /etc/ssh/sshd_config
echo PasswordAuthentication yes >> /etc/ssh/sshd_config

systemctl restart ssh

echo deb http://ftp.de.debian.org/debian buster main > /etc/apt/sources.list
echo deb-src http://ftp.br.debian.org/debian/ buster main >> /etc/apt/sources.list
echo deb http://security.debian.org/debian-security buster/updates main >> /etc/apt/sources.list
echo deb-src http://security.debian.org/debian-security buster/updates main >> /etc/apt/sources.list
echo deb http://ftp.br.debian.org/debian/ buster-updates main >> /etc/apt/sources.list
echo deb-src http://ftp.br.debian.org/debian/ buster-updates main >> /etc/apt/sources.list

echo nameserver 8.8.8.8 > /etc/resolv.conf
echo nameserver 4.2.2.2 >> /etc/resolv.conf

systemctl restart networking.service
apt-get update

sudo adduser developer
sudo passwd developer
sudo smbpasswd -a developer
sudo gpasswd -a developer users

apt-get install samba
mkdir /home/dados
chmod 777 -R /home/dados/
cp /etc/samba/smb.conf /etc/samba/smb.conf.old

echo wins support = yes >> /etc/samba/smb.conf
echo [dados] >> /etc/samba/smb.conf
echo path = /home/dados >> /etc/samba/smb.conf
echo create mask = 777 >> /etc/samba/smb.conf
echo directory mask = 777 >> /etc/samba/smb.conf
echo browsable = yes >> /etc/samba/smb.conf
echo guest ok = yes >> /etc/samba/smb.conf
echo read only = no >> /etc/samba/smb.conf
echo public = yes >> /etc/samba/smb.conf

echo [site] >> /etc/samba/smb.conf
echo comment = site >> /etc/samba/smb.conf
echo path = /var/www/html/site >> /etc/samba/smb.conf
echo valid users = @users >> /etc/samba/smb.conf
echo force group = users >> /etc/samba/smb.conf
echo create mask = 0660 >> /etc/samba/smb.conf
echo directory mask = 0775 >> /etc/samba/smb.conf
echo writable = yes >> /etc/samba/smb.conf

mkdir /var/www/html/site
chmod 0775 -R /var/www/html/site/
chown developer:users -R /var/www/html/site/
systemctl restart smbd

apt-get -y install mariadb-server mariadb-client
mysql_secure_installation
#123
#Y
#123
#Y
#Y
#n
#Y
apt-get -y install apache2

apt-get install php7.3
apt-get -y install php-apcu
apt-get install php7.3-apc
apt-get install php7.3-cli php7.3-common php7.3-curl php7.3-gd php7.3-json php7.3-mbstring php7.3-mysql php7.3-xml

wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.tar.gz
tar xvf phpMyAdmin-4.9.0.1-all-languages.tar.gz
sudo mv phpMyAdmin-4.9.0.1-all-languages/ /usr/share/phpmyadmin
sudo mkdir -p /var/lib/phpmyadmin/tmp
sudo chown -R www-data:www-data /var/lib/phpmyadmin
sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php

#sudo nano /usr/share/phpmyadmin/config.inc.php
#$cfg['blowfish_secret'] = 'STRINGOFTHIRTYTWORANDOMCHARACTERS';

sudo apt install pwgen

sudo cat phpmyadmin.conf > /etc/apache2/conf-available/phpmyadmin.conf

sudo a2enconf phpmyadmin.conf
sudo systemctl reload apache2

sudo nano /usr/share/phpmyadmin/config.inc.php
#descomentar pma
#setar senha igual ao user do mariadb
#$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
sudo mkdir -p /var/share/phpmyadmin/tmp
chmod 777 /var/share/phpmyadmin/tmp/

#mariadb
mariadb < /usr/share/phpmyadmin/sql/create_users.sql

echo AddDefaultCharset UTF-8 >> /etc/apache2/conf-enabled/charset.conf

apt-get install curl
sudo apt install net-tools -y

#####Copiar sistema
rsync -chavzP -e "ssh -p 22222" root@192.168.15.2:/var/www/html/site/ /var/www/html/site/

####php.ini
#nano /etc/php/7.3/apache2/php.ini
#max_execution_time = 300
#max_input_time = 300
#max_input_vars = 5000
#memory_limit = 1024M
#post_max_size = 1024M
#upload_max_filesize = 512M
#upload_tmp_dir = /tmp
#session.save_path = "/var/lib/php/sessions"

sudo apt-get install php7.3-zip

####Copiar banco
mariadb -u root -p fr_dev < /var/www/html/banco.sql

#https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-debian-10
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
cat ssl-params.conf > /etc/apache2/conf-available/ssl-params.conf
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak

a2enmod ssl
a2enmod headers
systemctl restart apache2

sudo a2ensite default-ssl
sudo a2enconf ssl-params
sudo apache2ctl configtest

systemctl reboot

sudo nano /etc/network/interfaces
iface enp0s8 inet static
address 192.168.15.99
netmask 255.255.255.0
network 192.168.15.1
broadcast 192.168.15.255
gateway 192.168.15.1
systemctl restart networking
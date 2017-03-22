#!/bin/bash
#========================================================
#>>title     refresh apt packages & update
#========================================================
sudo apt-get -q update && sudo apt-get -q upgrade -y || exit 1

#!/bin/bash
#========================================================
#>>title     install optional OS packages
#========================================================
sudo apt-get -q install -y wget curl vim sudo screen git dnsutils openssl pwgen || exit 1

#!/bin/bash 
#========================================================
#== install mysql server
#========================================================

MYCNF=~build/.my.cnf
touch $MYCNF
cat << !! > $MYCNF
[client]
user = root
password = 
host = localhost
!!
sudo chmod 400 $MYCNF  || exit 1
sudo chown build $MYCNF  || exit 1

sudo DEBIAN_FRONTEND=noninteractive apt-get -q install -y mysql-server mysql-client || exit 1

sudo cp $MYCNF ~root || exit 1
sudo chown root ~root/$( basename $MYCNF ) || exit 1

sudo /etc/init.d/mysql status 
mysql -e 'select 9999;' || exit 1


#!/bin/bash 
#========================================================
#== install nginx server
#========================================================
sudo DEBIAN_FRONTEND=noninteractive apt-get -q install -y nginx || exit 1

#!/bin/bash 
#========================================================
#== install php server
#========================================================
sudo DEBIAN_FRONTEND=noninteractive apt-get -q install -y php5-fpm php5-mysql || exit 1

#!/bin/bash
#========================================================
#== install phpmyadmin 
# this has to be done before the root mysql password is set so that autoinstalls correctly
#========================================================
sudo DEBIAN_FRONTEND=noninteractive apt-get -q install -y phpmyadmin || exit 1

#!/bin/bash
#========================================================
#== fix root password on mysql post phpadmin install
#========================================================

mysqlroot=$( pwgen --secure -C 12 1 | sed -e 's/ .*$//' )
# 'sed' is required in above statement to remove anoying trailing space
[[ $mysqlroot = "" ]] && exit 1

mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${mysqlroot}');" || exit 1

MYCNF=~build/.my.cnf
sudo chmod 600 $MYCNF  || exit 1
cat << !! > $MYCNF
[client]
user = root
password = $mysqlroot
host = localhost

[mysql]
prompt="[\\u@\\h - \\d]>\\n\\nmysql> "
!!
sudo chmod 400 $MYCNF  || exit 1
sudo cp $MYCNF ~root || exit 1
sudo chown root ~root/$( basename $MYCNF ) || exit 1

mysql -e 'select 9999;' || exit 1


#!/bin/bash
#========================================================
#== fix root password on mysql post phpadmin install
#========================================================

# configure nginx
# set timezone
# configgure php
# configure phpadmin
# seperate git package for certificates?
# build as an image?
# how switch between images? - e.g. dns switch? ip ownership switch?
#     # remove existing assigned external ip
#     gcloud compute instances delete-access-config oasis-test --access-config-name oasis1 --zone us-west1-b
#     # assign existing external ip ideally a statis one
#     gcloud compute instances add-access-config oasis-test --access-config-name oasis1 --address 35.185.222.178 --zone us-west1-b
#	  # not sure if we need to remove associate to other server?A
#     # need to build a script and a test rig - need to allow a 40 sec response test?
# security list
#
# nginx test



exit 0

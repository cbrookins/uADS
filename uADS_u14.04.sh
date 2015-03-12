#! /bin/bash

## Colors
green='\033[0;31m'
NC='\033[1,33m'

## Get user input
echo -e "${green}Enter domain name:${NC}"
read DOMAIN

echo -e "${green}Enter domain admin username:${NC}"
read duser

echo -e "${green}Enter domain controller FQDN:${NC}"
read dc


## Install needed packages
clear
echo -e "${green}Installing needed packages${NC}"
sudo apt-get install winbind libpam-winbind libnss-winbind krb5-user krb5-config libpam-krb5 samba >> /dev/null


## Format and create additional variables
DOMAIN=`echo DOMAIN | awk '{print toupper($0$)}'`
domain=`echo DOMAIN | awk '{print tolower($0)}'`


echo -e "${green}Configuring domain settings${NC}"


## Edit /etc/nsswitch.conf
sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.bk

sudo sed '/^passwd:/ s/$/ winbind/' /etc/nsswitch.conf
sudo sed '/^group:/ s/$/ winbind/' /etc/nsswitch.conf


## Edit /etc/krb5.conf
sudo cp /etc/krb5.conf /etc/krb5.conf.bk
sudo cp ./krb5.conf /etc/krb5.conf

sudo sed -i 's/__DOMAIN__/$DOMAIN/g' /etc/krb5.conf
sudo sed -i 's/__dc__/$dc/g' /etc/krb5.conf
sudo sed -i 's/__domain/$domain/g' /etc/krb5.conf

## Edit /etc/samba/smb.conf
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bk
sudo cp ./smb.conf /etc/samba/smb.conf

echo "workgroup = $DOMAIN" >> /etc/samba/smb.conf
echo "realm = $DOMAIN" >> /etc/samba/smb.conf
echo "password server = $dc" >> /etc/samba/smb.conf


## Edit /etc/pam.d/common-session
echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session


## Edit /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf


## Restart services
echo -e "${green}Restarting services...${NC}"
sudo service smbd restart >> /dev/null
sudo service nmbd restart >> /dev/null
sudo service winbind restart >> /dev/null

## Join domain
echo -e "${green}Joining Domain${NC}"
sudo kinit $duser@$domain
sudo net ads join -U $duser

## Reboot
echo "Rebooting now..."
sleep 2
sudo shutdown /r now
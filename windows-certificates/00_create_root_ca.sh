#!/bin/bash

# where to create the keys
CERTS_FOLDER="$1"

if [[ -z ${CERTS_FOLDER} ]]
then
	echo "$0 <local_certs_dir>" >&2
	exit 1
fi

CA_FOLDER=${CERTS_FOLDER}/ca
mkdir -p ${CA_FOLDER}

openssl genrsa -out ${CA_FOLDER}/rootCA.key 2048

openssl req -new -x509 -key ${CA_FOLDER}/rootCA.key -out ${CA_FOLDER}/rootCA.pem

# TODO

#You are about to be asked to enter information that will be incorporated
#into your certificate request.
#What you are about to enter is what is called a Distinguished Name or a DN.
#There are quite a few fields but you can leave some blank
#For some fields there will be a default value,
#If you enter '.', the field will be left blank.
#-----
#Country Name (2 letter code) [AU]:DE
#State or Province Name (full name) [Some-State]:Berlin
#Locality Name (eg, city) []:Berlin
#Organization Name (eg, company) [Internet Widgits Pty Ltd]:Toll Collect GmbH
#Organizational Unit Name (eg, section) []:BDS-BZS
#Common Name (e.g. server FQDN or YOUR name) []:SdK 2.0
#Email Address []:
#An optional company name []:

# Seems to depend on:
#ca-certificates.noarch : The Mozilla CA root certificate bundle
#python3-certifi.noarch : Python 3 package for providing Mozilla's CA Bundle
#python2-certifi.noarch : %{sum}

#4 - (run only once on Core and Tower Servers)
#$ echo "# Ansible Local PKI" >> /usr/lib/python2.7/site-packages/certifi/cacert.pem
#$ echo "# Created on $(date)" >> /usr/lib/python2.7/site-packages/certifi/cacert.pem
#$ cat {{ local_certs_dir }}/server_certificates/ssl/ca/rootCA.pem >> /usr/lib/python2.7/site-packages/certifi/cacert.pem
#
#4a) if there is an upgrade/update on ansible, the previous 3 commands have to be repeated

#Also tried:
#sudo cp certs.local.d/ca/rootCA.pem /etc/pki/ca-trust/source/anchors/TC_rootCA.pem
#sudo update-ca-trust
#sudo dnf install python2-certifi (ca-certificates and python3-certifi already installed)
## (updates /etc/pki/tls/certs/ca-bundle.crt,
## pointing to /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem)

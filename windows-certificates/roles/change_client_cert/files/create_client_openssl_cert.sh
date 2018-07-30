#!/bin/bash

# where to create the keys
CERTS_FOLDER="$1"
# set the name of the local user that will have the key mapped to
USERNAME="$2"

if [[ -z "${USERNAME}" || -z ${CERTS_FOLDER} ]]
then
	echo "$0 <local_certs_dir> <username>" >&2
	exit 1
fi

export OPENSSL_CONF=${CERTS_FOLDER}/openssl_${USERNAME}.conf

CURR_DIR=${CERTS_FOLDER}/client_certificates/current_certificates/
OLD_DIR=${CERTS_FOLDER}/client_certificates/old_certificates/

mkdir -p ${CURR_DIR} ${OLD_DIR}

cat > ${OPENSSL_CONF} << EOL
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req_client]
extendedKeyUsage = clientAuth
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:$USERNAME@localhost
EOL

bak=$(date +%Y%m%d_%H%M)
for file in openssl_cert_new.pem openssl_cert_key_new.pem
do
	if [ -f "${CURR_DIR}/${file}" ]
	then
		mv "${CURR_DIR}/${file}" "${OLD_DIR}/${file}_${bak}"
	fi
done

openssl req -x509 -nodes -days 1096 -newkey rsa:2048 \
	-out ${CURR_DIR}/openssl_cert_new.pem -outform PEM \
	-keyout ${CURR_DIR}/openssl_cert_key_new.pem \
	-subj "/CN=$USERNAME" -extensions v3_req_client

rm ${OPENSSL_CONF}

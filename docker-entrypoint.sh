#!/bin/ash
# Copyright 2016-2017 LasLabs Inc.
# License Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0.html).

set -e

# Generate keys if necessary
if [ ! -f /etc/cfssl/ca.pem ] || [ ! -f /etc/cfssl/ca-key.pem ] ; then

    # Create root if no API URI
    if [ ! "${CA_ROOT_URI}" ] ; then
        init-ca-root
    # Otherwise create a CSR, then have the Root CA sign
    else
        init-ca-intermediate
    fi

fi

if [ "${DB_INIT}" -eq "1" ] || [ "${DB_DESTROY}" -eq "1" ] ; then
    init-db
fi

# Add config flags if cfssl
if [ "${1}" = 'cfssl' ]; then
	set -- "$@" -config="/etc/cfssl/${CFSSL_CONFIG}" -db-config="/etc/cfssl/${DB_CONFIG}"
fi

exec "$@"

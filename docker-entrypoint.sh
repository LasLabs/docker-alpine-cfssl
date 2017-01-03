#!/bin/ash
# Copyright 2016 LasLabs Inc.
# # License MIT (https://opensource.org/licenses/MIT).

set -e

if [ ! -f $CFSSL_DATA/csr_ca.json ];
then

    cfssl gencert -initca $CFSSL_DATA/csr_ca.json | cfssljson -bare ca

fi

# Add cfssl as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- cfssl "$@"
fi

# As argument is not related to cfssl,
# then assume that user wants to run their own process,
# for example a `bash` shell to explore this image
exec "$@"

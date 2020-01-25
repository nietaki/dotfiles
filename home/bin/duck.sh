#!/usr/bin/env sh
echo "quack!"
# stolen from https://github.com/davidjb/update-dynamic-dns/blob/master/update-duckdns.sh

if [ "$1" = "--help" ]; then
    echo "Usage: $0 domain token"
    echo "Updates Duck DNS with an IP address for a given domain."
    echo "Omitting the interface causes Duck DNS to determine the public IP of your location."
    exit
fi

DOMAIN=$1
TOKEN=$2

if [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then
    echo "Both domain and token are required. Aborting."
    exit 1;
fi

mkdir -p ~/.duckdns

curl -k -o ~/.duckdns/duck.log "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip="

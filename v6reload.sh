#!/bin/bash
cloudflare_auth_email=$1
cloudflare_auth_key=$2
if [ -z "$cloudflare_auth_email" ]
then
      echo "cloudflare_auth_email is empty"
fi
if [ -z "$cloudflare_auth_key" ]
then
      echo "cloudflare_auth_key is empty"
fi

# Get the current external IP address
ip=$(ip addr show dev eth0 | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d' | grep -v ^fe80 | grep -v ^fc00)
if [ -z "$ip" ]
then
      echo "you dont have a public ipv6 currently"
      exit 1
fi

echo "Current IP is $ip"

zones=('goapi.cc' 'go-er.co')

for zone in ${zones[@]}; do
 dnsrecord=ipv6.$(hostname).$zone

 if host $dnsrecord 1.1.1.1 | grep "has IPv6 address" | grep "$ip"; then
   echo "no changes needed"
   continue
 fi

 # get the zone id for the requested zone
 zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
   -H "X-Auth-Email: $cloudflare_auth_email" \
   -H "X-Auth-Key: $cloudflare_auth_key" \
   -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

 echo "Zoneid for $zone is $zoneid"

 # get the dns record id
 dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=AAAA&name=$dnsrecord" \
   -H "X-Auth-Email: $cloudflare_auth_email" \
   -H "X-Auth-Key: $cloudflare_auth_key" \
   -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

 echo "DNSrecordid for $dnsrecord is $dnsrecordid"

 # update the record
 curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
   -H "X-Auth-Email: $cloudflare_auth_email" \
   -H "X-Auth-Key: $cloudflare_auth_key" \
   -H "Content-Type: application/json" \
   --data "{\"type\":\"AAAA\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":true}" | jq

 # update the record
 curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
   -H "X-Auth-Email: $cloudflare_auth_email" \
   -H "X-Auth-Key: $cloudflare_auth_key" \
   -H "Content-Type: application/json" \
   --data "{\"type\":\"AAAA\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":true}" | jq

done

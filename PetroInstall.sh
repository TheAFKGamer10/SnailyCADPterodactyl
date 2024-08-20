apt update
apt install -y git curl wget

mkdir -p /mnt/server
cd /mnt/server

rm -f snailycadptero.cjs
rm -rf snaily-cadv4
wget https://raw.githubusercontent.com/TheAFKGamer10/SnailyCADPterodactyl/main/snailycadptero.cjs
node snailycadptero.cjs $CLIENT_URL $API_URL $CLIENT_PORT $API_PORT $DOMAIN $SECURE_COOKIES_FOR_IFRAME
rm -f snailycadptero.cjs

echo -e "Install Complete"
exit 0
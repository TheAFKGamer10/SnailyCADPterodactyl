apt update
apt install -y git curl wget

mkdir -p /mnt/server
cd /mnt/server

ACTIVITY=${ACTIVITY// /_}

rm -f snailycadbotptero.cjs
rm -rf snailycad-bot
wget https://raw.githubusercontent.com/TheAFKGamer10/SnailyCADPterodactyl/main/bot/snailycadbotptero.cjs
node snailycadbotptero.cjs $BOT_TOKEN $ACTIVITY $ACTIVITYTYPE

echo -e "Install Complete"
exit 0
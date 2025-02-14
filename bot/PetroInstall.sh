apt update
apt install -y git curl jq

mkdir -p /mnt/server
cd /mnt/server

# Fetch random password
PASS=$(curl -s 'https://www.random.org/strings/?num=1&len=20&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain' | tr -d '\n\r')

# Clone the repository
echo "Cloning"
git clone https://github.com/SnailyCAD/snailycad-bot.git
cp -rf snailycad-bot/. .
rm -rf snailycad-bot
cp .env.example .env

# Update .env file
echo "Changing ENV"
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=\"$PASS\"|" .env
sed -i "s|POSTGRES_USER=.*|POSTGRES_USER=\"snailycadbot\"|" .env
sed -i "s|DB_PORT=.*|DB_PORT=\"5432\"|" .env
sed -i "s|BOT_TOKEN=.*|BOT_TOKEN=\"$BOT_TOKEN\"|" .env

# Update activity in ready.ts
echo "Setting Activity"
READY_TS="./src/events/client/ready.ts"
sed -i "s|bot.user?.setActivity(\"snailycad.org\", { type: DJS.ActivityType.Watching });|bot.user?.setActivity(\"${ACTIVITY//_/ }\");|" $READY_TS

echo -e "Install Complete"
exit 0
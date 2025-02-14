apt update
apt install -y git curl wget jq

mkdir -p /mnt/server
cd /mnt/server

rm -f snailycadptero.cjs
rm -rf snaily-cadv4

# Fetch random secrets
SECRET=$(curl -s 'https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain' | tr -d '\n\r')
PASS=$(curl -s 'https://www.random.org/strings/?num=1&len=20&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain' | tr -d '\n\r')

# Clone the repository
echo "Cloning"
git clone https://github.com/SnailyCAD/snaily-cadv4.git
cp -rf snaily-cadv4/. .
rm -rf snaily-cadv4
cp .env.example .env

# Update .env file
echo "Changing ENV"
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=\"$PASS\"|" .env
sed -i "s|POSTGRES_USER=.*|POSTGRES_USER=\"snailycad\"|" .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=\"$SECRET\"|" .env
sed -i "s|ENCRYPTION_TOKEN=.*|ENCRYPTION_TOKEN=\"$SECRET\"|" .env
sed -i "s|CORS_ORIGIN_URL=.*|CORS_ORIGIN_URL=\"$CLIENT_URL\"|" .env
sed -i "s|NEXT_PUBLIC_CLIENT_URL=.*|NEXT_PUBLIC_CLIENT_URL=\"$CLIENT_URL\"|" .env
sed -i "s|NEXT_PUBLIC_PROD_ORIGIN=.*|NEXT_PUBLIC_PROD_ORIGIN=\"$API_URL/v1\"|" .env
sed -i "s|PORT_CLIENT=.*|PORT_CLIENT=\"$CLIENT_PORT\"|" .env
sed -i "s|PORT_API=.*|PORT_API=\"$API_PORT\"|" .env
sed -i "s|DOMAIN=.*|DOMAIN=\"$DOMAIN\"|" .env
sed -i "s|SECURE_COOKIES_FOR_IFRAME=.*|SECURE_COOKIES_FOR_IFRAME=\"$SECURE_COOKIES_FOR_IFRAME\"|" .env

echo -e "Install Complete"
exit 0
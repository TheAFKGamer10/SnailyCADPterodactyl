const fs = require('fs');
const execSync = require('child_process').execSync;

fetch('https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain')
    .then(response => response.text())
    .then(pass => {
        const args = process.argv.slice(2);
        const data = {
            "POSTGRES_PASSWORD": args[0],
            "POSTGRES_USER": args[1],
            "JWT_SECRET": pass,
            "ENCRYPTION_TOKEN": pass,
            "CORS_ORIGIN_URL": args[2],
            "NEXT_PUBLIC_CLIENT_URL": args[2],
            "NEXT_PUBLIC_PROD_ORIGIN": args[3],
            "PORT_CLIENT": args[4],
            "PORT_API": args[5],
            "DOMAIN": args[6],
            "SECURE_COOKIES_FOR_IFRAME": args[7]
        };

        execSync(`cd /mnt/server`)
        execSync(`apt update`)
        execSync(`DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends apt-utils postgresql postgresql-contrib -y`)
        execSync(`DEBIAN_FRONTEND=noninteractive npm install -g pnpm`);
        execSync(`service postgresql start`)

        execSync(`echo "Adding User"`)
        execSync(`DEBIAN_FRONTEND=noninteractive psql -h localhost -d postgres -U postgres -c "CREATE USER snailycad WITH PASSWORD '${data['POSTGRES_PASSWORD']}' WITH SUPERUSER"`)
        execSync(`echo "Making Database"`)
        execSync(`DEBIAN_FRONTEND=noninteractive psql -h localhost -d postgres -U postgres -c "SELECT 'CREATE DATABASE snaily-cadv4 WITH OWNER = ${data['POSTGRES_USER']}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'snaily-cadv4')\gexec"`)

        execSync(`echo "Cloning"`)
        execSync(`git clone https://github.com/SnailyCAD/snaily-cadv4.git`)
        execSync(`cp snaily-cadv4/* .`)
        execSync(`echo "Installing Dependicies"`)
        execSync(`DEBIAN_FRONTEND=noninteractive pnpm install`)
        execSync(`cp .env.example .env`)
        execSync(`echo "Changing ENV"`)

        try {
            let envdir = './snaily-cadv4/.env';
            let fileContent = fs.readFileSync(envdir, 'utf-8');
            let fileLines = fileContent.split('\n');
            Object.keys(data).forEach(element => {
                let lineIndex = fileLines.findIndex(line => line.startsWith(element + '='));
                if (/^\d+$/.test(data[element])) {
                    fileLines[lineIndex] = element + '=' + (data[element] ? data[element] : '');
                } else {
                    fileLines[lineIndex] = element + '=\"' + data[element] + '\"';
                }
                fs.writeFileSync(envdir, fileLines.join('\n'));
            });
        } catch (error) {
            console.error('Error:', error);
        }

        execSync(`node scripts/copy-env.mjs --client --api`)
        execSync(`echo "Building"`)
        execSync(`DEBIAN_FRONTEND=noninteractive pnpm run build`)
    })
    .catch(error => {
        console.error('Error:', error);
    });
    

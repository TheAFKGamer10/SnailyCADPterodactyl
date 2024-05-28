const fs = require('fs');
const execSync = require('child_process').execSync;

fetch('https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain')
    .then(response => response.text())
    .then(data => {
        const args = process.argv.slice(2);
        const data = {
            "POSTGRES_PASSWORD": args[0],
            "POSTGRES_USER": args[1],
            "JWT_SECRET": args[2],
            "ENCRYPTION_TOKEN": args[2],
            "CORS_ORIGIN_URL": args[3],
            "NEXT_PUBLIC_CLIENT_URL": args[3],
            "NEXT_PUBLIC_PROD_ORIGIN": args[4],
            "PORT_CLIENT": args[5],
            "PORT_API": args[6],
            "DOMAIN": args[7],
            "SECURE_COOKIES_FOR_IFRAME": args[8]
        };

        execSync(`cd /mnt/server`)
        execSync(`apt update`)
        execSync(`apt install git node postgresql-14 postgresql-contrib -y`)
        execSync(`npm install -g pnpm`);
        execSync(`systemctl start postgresql.service`)
        execSync(`systemctl enable postgresql.service`)

        execSync(`psql -d postgres -c "DO
        $do$
        BEGIN
           IF EXISTS (
              SELECT FROM pg_catalog.pg_roles
              WHERE rolname = '${data['POSTGRES_USER']}') THEN
        
              RAISE NOTICE 'Role "${data['POSTGRES_USER']}" already exists. Skipping.';
           ELSE
              CREATE ROLE ${data['POSTGRES_USER']} LOGIN PASSWORD '${data['POSTGRES_PASSWORD']}' SUPERUSER;
           END IF;
        END
        $do$;"`)
        execSync(`psql -d postgres -c "SELECT 'CREATE DATABASE snaily-cadv4 WITH OWNER = ${data['POSTGRES_USER']}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'snaily-cadv4')\gexec"`)

        execSync(`git clone https://github.com/SnailyCAD/snaily-cadv4.git`)
        execSync(`cd snaily-cadv4 && pnpm install`)
        execSync(`cp .env.example .env`)

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
        execSync(`pnpm run build`)
        execSync(`pnpm run start`)
    })
    .catch(error => {
        console.error('Error:', error);
    });
    
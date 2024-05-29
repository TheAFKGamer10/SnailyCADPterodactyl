const fs = require('fs');
const execSync = require('child_process').execSync;

fetch('https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain')
    .then(response => response.text())
    .then(pass => {
        const args = process.argv.slice(2);
        const data = {
            "POSTGRES_PASSWORD": args[0],
            "POSTGRES_USER": args[1],
            "JWT_SECRET": pass.trim().replace(/\n/g, '').replace(/\r/g, ''),
            "ENCRYPTION_TOKEN": pass.trim().replace(/\n/g, '').replace(/\r/g, ''),
            "CORS_ORIGIN_URL": args[2],
            "NEXT_PUBLIC_CLIENT_URL": args[2],
            "NEXT_PUBLIC_PROD_ORIGIN": args[3],
            "PORT_CLIENT": args[4],
            "PORT_API": args[5],
            "DOMAIN": args[6],
            "SECURE_COOKIES_FOR_IFRAME": args[7]
        };

        execSync(`cd /mnt/server`, { stdio: 'inherit' });
        execSync(`apt update`, { stdio: 'inherit' });
        execSync(`DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends sudo postgresql postgresql-contrib -y`, { stdio: 'inherit' });
        execSync(`npm install -g pnpm`, { stdio: 'inherit' });
        execSync(`service postgresql start`, { stdio: 'inherit' });

        execSync(`echo "Adding User"`, { stdio: 'inherit' });
        execSync(`sudo -i -u postgres psql -d postgres -c "CREATE USER snailycad WITH PASSWORD '${data['POSTGRES_PASSWORD']}' SUPERUSER;"`, { stdio: 'inherit' });
        execSync(`echo "Making Database"`, { stdio: 'inherit' });
        execSync(`sudo -i -u postgres createdb -O snailycad snaily-cadv4 -T template0`, { stdio: 'inherit' });

        execSync(`echo "Cloning"`, { stdio: 'inherit' });
        execSync(`git clone https://github.com/SnailyCAD/snaily-cadv4.git`, { stdio: 'inherit' });
        execSync(`cp -rf snaily-cadv4/. .`, { stdio: 'inherit' });
        execSync(`echo "Installing Dependicies"`, { stdio: 'inherit' });
        execSync(`pnpm install`, { stdio: 'inherit' });
        execSync(`cp -rf .env.example .env`, { stdio: 'inherit' });
        execSync(`echo "Changing ENV"`, { stdio: 'inherit' });

        try {
            let envdir = './.env';
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

        execSync(`node scripts/copy-env.mjs --client --api`, { stdio: 'inherit' });
        execSync(`echo "Building"`, { stdio: 'inherit' });
        execSync(`pnpm run build`, { stdio: 'inherit' })
})
    .catch(error => {
        console.error('Error:', error);
    });

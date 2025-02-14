const fs = require('fs');
const execSync = require('child_process').execSync;

// Legacy Allert
execSync(`echo "This version of the egg is deprecated, please use the new version of the egg"`, { stdio: 'inherit' });
execSync(`echo "You can find the new version of the egg at: "https://github.com/TheAFKGamer10/SnailyCADPterodactyl"`, { stdio: 'inherit' });

fetch('https://www.random.org/strings/?num=1&len=32&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain')
    .then(response => response.text())
    .then(SECRET => {
        fetch('https://www.random.org/strings/?num=1&len=20&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain')
            .then(response => response.text())
            .then(PASS => {
                const args = process.argv.slice(2);
                const data = {
                    "POSTGRES_PASSWORD": PASS.trim().replace(/\n/g, '').replace(/\r/g, ''),
                    "POSTGRES_USER": "snailycad",
                    "JWT_SECRET": SECRET.trim().replace(/\n/g, '').replace(/\r/g, ''),
                    "ENCRYPTION_TOKEN": SECRET.trim().replace(/\n/g, '').replace(/\r/g, ''),
                    "CORS_ORIGIN_URL": args[0],
                    "NEXT_PUBLIC_CLIENT_URL": args[0],
                    "NEXT_PUBLIC_PROD_ORIGIN": `${args[1]}/v1`,
                    "PORT_CLIENT": args[2],
                    "PORT_API": args[3],
                    "DOMAIN": args[4],
                    "SECURE_COOKIES_FOR_IFRAME": args[5]
                };

                execSync(`cd /mnt/server`, { stdio: 'inherit' });

                execSync(`echo "Cloning"`, { stdio: 'inherit' });
                execSync(`git clone https://github.com/SnailyCAD/snaily-cadv4.git`, { stdio: 'inherit' });
                execSync(`cp -rf snaily-cadv4/. .`, { stdio: 'inherit' });
                execSync(`rm -rf snaily-cadv4`, { stdio: 'inherit' });
                execSync(`cp .env.example .env`, { stdio: 'inherit' });
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
            })
            .catch(error => {
                console.error('Error:', error);
            });
    })
    .catch(error => {
        console.error('Error:', error);
    });

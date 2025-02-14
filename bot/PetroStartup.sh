pnpm update && \
pnpm install && \
node scripts/copy-env.mjs --client --api && \
ehco "Now Building the CAD Application. This may take a few minutes." && \
pnpm run build > buildout.txt && \
pnpm run start
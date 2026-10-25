FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./

# The lockfile pins some packages to Databricks' internal npm mirror, which is
# unreachable outside Databricks. Point them at the public registry instead
# (tarball URL layout is identical, so the lockfile integrity hashes still match).
RUN sed -i 's|https://npm-proxy\.dev\.databricks\.com|https://registry.npmjs.org|g' package-lock.json \
    && npm ci

COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]

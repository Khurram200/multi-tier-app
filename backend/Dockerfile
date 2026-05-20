# Stage 1: install dependencies
FROM node:20 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Stage 2: minimal runtime image
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN npm prune --production \
    && chown -R node:node /app

USER node

EXPOSE 5000

CMD ["node", "server.js"]

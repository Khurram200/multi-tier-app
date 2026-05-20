# Stage 1: install dependencies
FROM node:20 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Stage 2: minimal runtime image (CRA dev server for local assessment)
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN npm prune --production \
    && chown -R node:node /app

USER node

ENV HOST=0.0.0.0
ENV PORT=3000
ENV CI=true
ENV BROWSER=none

EXPOSE 3000

CMD ["npm", "start"]

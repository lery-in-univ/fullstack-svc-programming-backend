FROM node:24.11.0-alpine AS builder

ENV NODE_ENV=build
WORKDIR /app

COPY . .

RUN npm ci
RUN npm run build

FROM node:24.11.0-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY --from=builder /app/package.json /app/package-lock.json  ./
COPY --from=builder /app/.env ./
COPY --from=builder /app/node_modules/ ./node_modules/
COPY --from=builder /app/dist/ ./dist/

CMD ["npm", "run", "start:prod"]

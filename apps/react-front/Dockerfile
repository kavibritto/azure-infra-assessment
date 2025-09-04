FROM public.ecr.aws/docker/library/node:iron-trixie-slim AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM public.ecr.aws/nginx/nginx:1.29-alpine

WORKDIR /usr/share/nginx/html

COPY --from=builder /app/dist/. .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
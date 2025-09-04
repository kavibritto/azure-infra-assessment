# Echo CRUD API + React Frontend

This project demonstrates a full-stack CRUD app:

-   **Backend:** Golang API using [Echo v4](https://echo.labstack.com/).
-   **Frontend:** React (Vite + Tailwind).
-   **Containerization:** Dockerfiles provided for both services.

------------------------------------------------------------------------

## 📦 Project Structure

    .
    ├── go-api/          # Go Echo API
    │   ├── main.go
    │   ├── go.mod
    │   └── Dockerfile
    ├── react-front/         # React + Vite + Tailwind
    │   ├── src/
    │   ├── index.html
    │   └── Dockerfile
    └── README.md

------------------------------------------------------------------------

## 🚀 Backend (Echo CRUD API)

### Features

-   REST endpoints under `/api/v1/items`
-   In-memory store with **Create / Read / Update / Delete**
-   Graceful shutdown, logging, CORS, secure headers
-   Health endpoint: `GET /healthz`

### Run locally

``` bash
cd backend
go mod tidy
go run .
```

The API will listen on `http://localhost:8080`.

### Example requests

``` bash
curl -s http://localhost:8080/healthz

curl -X POST http://localhost:8080/api/v1/items   -H 'Content-Type: application/json'   -d '{"name":"Laptop Stand","price":1499}'
```

------------------------------------------------------------------------

## 🎨 Frontend (React + Vite + Tailwind)

### Features

-   Form to **create / update items**
-   List view with **edit & delete**
-   Axios calls proxied to backend (`/api` → `http://localhost:8080`)

### Run locally

``` bash
cd frontend
npm install
npm run dev
```

Visit <http://localhost:3000>.

------------------------------------------------------------------------

## 🐳 Docker Setup

### Backend Dockerfile (`go-api/Dockerfile`)

``` dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o bin/goapi .

FROM alpine:latest
WORKDIR /app
COPY --from=builder ./app/bin/goapi .
EXPOSE 8080
CMD [ "/app/goapi" ]
```

### Frontend Dockerfile (`react-front/Dockerfile`)

``` dockerfile
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
```

------------------------------------------------------------------------

## 🔧 Build & Run with Docker

### Backend

``` bash
cd backend
docker build -t go-api .
docker run -p 8080:8080 go-api
```

### Frontend

``` bash
cd react-front
docker build -t react-front .
docker run -p 3000:80 react-front
```

Open <http://localhost:3000>.


------------------------------------------------------------------------

## ✅ Next Steps
-   CI/CD with GitHub Actions → build & push Docker images.
-   Deploy on AKS with ACR (you already set up AKS + ACR integration).

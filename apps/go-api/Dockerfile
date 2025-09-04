FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o bin/goapi .

FROM alpine:latest
WORKDIR /app
COPY --from=builder ./app/bin/goapi .
EXPOSE 8080
CMD [ "/app/goapi" ]
ROM golang:1.26.2-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build  -o land-invader-server ./server

FROM alpine:3.21
WORKDIR /usr/local/app
COPY --from=build /land-invader-server ./land-invader-server

CMD ["./land-invader-server"]
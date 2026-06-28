FROM golang:1.26.2-alpine AS build
ARG VERSION=unknown
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /land-invader-server ./server

FROM alpine:3.21
WORKDIR /usr/local/app
COPY --from=build /land-invader-server ./land-invader-server
CMD ["./land-invader-server"]
FROM golang:1.20.3-alpine3.17 AS build

# Install dependencies:
RUN apk update && apk add curl
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.52.2

FROM golang:1.20.3-alpine3.17
LABEL maintainer="Victor \"Vito\" Gama <victor.gama@gympass.com>"

RUN apk update && apk add \
    ruby && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*.

WORKDIR /usr/src/app/

COPY --from=build /usr/local/bin/golangci-lint /usr/local/bin/golangci-lint
COPY engine.json /

RUN adduser -S -u 9000 --shell /bin/false app
USER app

COPY . ./

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/bin/codeclimate-golangci-lint"]

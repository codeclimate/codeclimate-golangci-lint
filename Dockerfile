FROM golang:latest AS build

# Install dependencies:
RUN apt-get update && apt-get -y install curl
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.45.2

FROM golang:latest
LABEL maintainer="Victor \"Vito\" Gama <victor.gama@gympass.com>"

RUN apt-get update && apt-get -y install build-essential ruby && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*.

WORKDIR /usr/src/app/

COPY --from=build /usr/local/bin/golangci-lint /usr/local/bin/golangci-lint
COPY engine.json /

RUN adduser -u 9000 --shell /bin/false app
USER app

COPY . ./

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/entrypoint.sh"]

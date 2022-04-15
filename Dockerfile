FROM golang:bullseye
LABEL maintainer="Victor \"Vito\" Gama <victor.gama@gympass.com>"

WORKDIR /usr/src/app/

COPY engine.json /

# Install dependencies:
RUN apt-get update && apt-get -y install build-essential curl git ruby
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.45.2

RUN adduser -u 9000 --shell /bin/false app
USER app

COPY . ./

VOLUME /code
WORKDIR /code

CMD ["/usr/src/app/entrypoint.sh"]

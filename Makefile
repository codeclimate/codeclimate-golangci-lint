.PHONY: image

IMAGE_NAME ?= codeclimate/codeclimate-golangci

image:
	docker build --rm -t $(IMAGE_NAME) .

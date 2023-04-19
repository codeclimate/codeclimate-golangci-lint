.PHONY: image test docs bundle release

IMAGE_NAME ?= codeclimate/codeclimate-golangci-lint
RELEASE_REGISTRY ?= codeclimate

ifndef RELEASE_TAG
override RELEASE_TAG = latest
endif

image:
	docker build --rm -t $(IMAGE_NAME) .

release:
	docker tag $(IMAGE_NAME) $(RELEASE_REGISTRY)/codeclimate-golangci-lint:$(RELEASE_TAG)
	docker push $(RELEASE_REGISTRY)/codeclimate-golangci-lint:$(RELEASE_TAG)

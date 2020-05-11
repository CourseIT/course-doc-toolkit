DOCKER_USERNAME ?= lihame
DOCKER_IMAGE_NAME ?= course-doc
DOCKER_IMAGE_TAG ?= latest
DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
 
ASCIIDOCTOR_VERSION ?= 2.0.10

export DOCKER_IMAGE_NAME_TO_TEST \
  ASCIIDOCTOR_VERSION

all: build test

build:
	docker build \
		--tag="$(DOCKER_IMAGE_NAME_TO_TEST)" \
		--file=Dockerfile \
		$(CURDIR)/

test:
	/usr/local/bin/bats $(CURDIR)/tests/*.bats


deploy:
	echo $(DOCKER_PASSWORD) | docker login -u $(DOCKER_USERNAME) --password-stdin
	docker push $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

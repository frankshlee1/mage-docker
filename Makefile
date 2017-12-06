# Name of the image
#name := mage/mage
name := frankshlee1/mage-docker

# Default set of version for `make all`
versions ?= $(shell curl -L -s \
                    'https://registry.hub.docker.com/v2/repositories/library/node/tags?page_size=1024' \
                    | jq -r '.results[]["name"]' | grep -v onbuild | sort )

# Latest Node version supported
latest ?= $(shell curl -L -s \
                  'https://registry.hub.docker.com/v2/repositories/library/node/tags?page_size=1024' \
                  | jq -r '.results[]["name"]' | grep -v onbuild | sort -n | awk '/[0-9.]+$$/' | tail -n 1)

# Default version for `make build`
version := $(latest)

.PHONY: build-version build release-version git-push push-all release

build-version:
	$(if $(findstring alpine,$(version)), \
	    docker build -t $(name):$(version) --build-arg=node_version=$(version) -f alpine/Dockerfile ., \
	    docker build -t $(name):$(version) --build-arg=node_version=$(version) -f debian/Dockerfile .)
	docker tag $(name):$(version) $(name):$(version)
	test $(version) = $(latest) && docker tag $(name):$(version) $(name):latest || true

build:
	for version in $(versions); do \
		echo ">> Building version $${version}"; \
		$(MAKE) build-version version=$${version} latest=$(latest) "versions=$(versions)" || exit $${?}; \
	done

release-version:
	docker push $(name):$(version)
	test $(version) = $(latest) && docker push $(name):latest || true

push-all:
	for version in $(versions); do \
		echo ">> Pushing version $${version}"; \
		$(MAKE) release-version version=$${version} latest=$(latest) "versions=$(versions)" || exit $${?}; \
	done

git-push:
	git push git@github.com:tokyowizard/mage-docker.git master

release: git-push
	for version in $(versions); do \
		echo ">> Release version $${version}"; \
		$(MAKE) release-version version=$${version} latest=$(latest) "versions=$(versions)" || exit $${?}; \
	done
	$(MAKE) release-version version=latest

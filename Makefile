ARCHITECTURES = amd64 arm32v6 arm64v8
QEMU_STATIC = https://github.com/multiarch/qemu-user-static/releases/download/v2.8.0
IMAGE = alpine:3.5
MULTIARCH = multiarch/qemu-user-static:register
TMP_DIR = tmp
TMP_DOCKERFILE = Dockerfile.generated
VERSION = $(shell cat VERSION)
ifeq ($(REPO),)
  REPO = picapport
endif
ifeq ($(TRAVIS_BRANCH),)
	TAG = latest
else
  ifeq ($(TRAVIS_BRANCH), master)
    TAG = latest
  else
    TAG = $(TRAVIS_BRANCH)
	endif
endif

all: $(ARCHITECTURES)

$(ARCHITECTURES):
	@mkdir -p $(TMP_DIR)
	@curl -L -o $(TMP_DIR)/qemu-$@-static.tar.gz $(QEMU_STATIC)/qemu-$(strip $(call convert_archs,$@))-static.tar.gz
	@tar xzf $(TMP_DIR)/qemu-$@-static.tar.gz -C $(TMP_DIR)
	@sed -e "s|<IMAGE>|$@/$(IMAGE)|g" \
		-e "s|<ARCH>|$@|g" \
		-e "s|<QEMU>|COPY $(TMP_DIR)/qemu-$(strip $(call convert_archs,$@))-static /usr/bin/qemu-$(strip $(call convert_archs,$@))-static|g" \
		Dockerfile.generic > $(TMP_DOCKERFILE)
	@sed -i -e "s|amd64/$(IMAGE)|$(IMAGE)|g" $(TMP_DOCKERFILE)
	@docker run --rm --privileged $(MULTIARCH) --reset
	@docker build --build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VCS_URL=$(shell git config --get remote.origin.url) \
			--build-arg VERSION=$(VERSION) \
			-f $(TMP_DOCKERFILE) -t $(REPO):linux-$@-$(TAG) .
	@rm -rf $(TMP_DIR) $(TMP_DOCKERFILE)

push:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	$(foreach arch,$(ARCHITECTURES), docker push $(REPO):linux-$(arch)-$(TAG);)
	@docker logout

clean:
	@rm -rf $(TMP_DIR) $(TMP_DOCKERFILE)

define convert_archs
	$(shell echo $(1) | sed -e "s|arm32.*|arm|g" -e "s|arm64.*|aarch64|g" -e "s|amd64|x86_64|g")
endef

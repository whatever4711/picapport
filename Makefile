ARCHITECTURES = amd64 arm32v6 arm64v8
QEMU_STATIC = https://github.com/multiarch/qemu-user-static/releases/download/v2.8.0
IMAGE = alpine:latest
MULTIARCH = multiarch/qemu-user-static:register
TMP_DIR = tmp
TMP_DOCKERFILE = Dockerfile.generated
VERSION = $(shell cat VERSION)
#DOCKER_USER = test
#DOCKER_PASS = test
ifeq ($(REPO),)
  REPO = picapport
endif
ifeq ($(CIRCLE_TAG),)
	TAG = latest
else
	TAG = $(CIRCLE_TAG)
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
	@$(foreach arch,$(ARCHITECTURES), docker push $(REPO):linux-$(arch)-$(TAG);)
	@docker logout

manifest:
	@wget -O docker https://6582-88013053-gh.circle-artifacts.com/1/work/build/docker-linux-amd64
	@chmod +x docker
	@./docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@./docker manifest create $(REPO):$(TAG) $(foreach arch,$(ARCHITECTURES), $(REPO):linux-$(arch)-$(TAG))
	@$(foreach arch,$(ARCHITECTURES), ./docker manifest annotate $(REPO):$(TAG) $(REPO):linux-$(arch)-$(TAG) --os linux $(strip $(call convert_variants,$(arch)));)
	@./docker manifest push $(REPO):$(TAG)
	@./docker logout

clean:
	@rm -rf $(TMP_DIR) $(TMP_DOCKERFILE)

define convert_archs
	$(shell echo $(1) | sed -e "s|arm32.*|arm|g" -e "s|arm64.*|aarch64|g" -e "s|amd64|x86_64|g")
endef

define convert_variants
	$(shell echo $(1) | sed -e "s|amd64|--arch amd64|g" -e "s|arm32v5|--arch arm --variant v5|g" -e "s|arm32v6|--arch arm --variant v6|g" -e "s|arm32v7|--arch arm --variant v7|g" -e "s|arm64v8|--arch arm64 --variant v8|g")
endef

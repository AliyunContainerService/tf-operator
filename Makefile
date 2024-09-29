.SILENT:

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

GIT_REPO := $(shell git remote -v | awk '{print $$2}' | head -n1)
GIT_BRANCH := $(shell git branch --show-current)
GIT_SHORT_COMMIT_ID := $(shell git rev-parse --short HEAD)

# Versions
CONTROLLER_TOOLS_VERSION ?= v0.15.0

# Binaries
CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen-$(CONTROLLER_TOOLS_VERSION)

# Location to install binaries
LOCALBIN ?= $(shell pwd)/bin

IMG ?= registry.cn-beijing.aliyuncs.com/acs/tf_operator
VERSION ?= v1.0-aliyun
GIT_SHORT_COMMIT=$(shell git rev-parse --short HEAD)
TAG=${VERSION}-${GIT_SHORT_COMMIT}

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: manifests
manifests: controller-gen ## Generate CustomResourceDefinition, RBAC and WebhookConfiguration manifests.
	GO111MODULE=off $(CONTROLLER_GEN) crd:generateEmbeddedObjectMeta=true rbac:roleName=manager-role webhook paths="./pkg/apis/tensorflow/v1" output:crd:artifacts:config=manifests/base/crds

.PHONY: generate
generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	GOPATH=$(shell go env GOPATH) GO111MODULE=off hack/update-codegen.sh

##@ Build

.PHONY: build
build: ## build exec file gpushare-device-plugin on host
	@docker build . --rm --no-cache -t ${IMG}:${TAG}

##@ Dependencies

$(LOCALBIN):
	mkdir -p $(LOCALBIN)

.PHONY: controller-gen
controller-gen: $(CONTROLLER_GEN) ## Download controller-gen locally if necessary.
$(CONTROLLER_GEN): $(LOCALBIN)
	$(call go-install-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen,$(CONTROLLER_TOOLS_VERSION))

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary (ideally with version)
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f $(1) ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv "$$(echo "$(1)" | sed "s/-$(3)$$//")" $(1) ;\
}
endef

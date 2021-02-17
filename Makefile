GOPATH ?= $(HOME)/go
BIN_DIR = $(GOPATH)/bin

PACKAGE = go-embed-migration-source
NAMESPACE = https://github.com/Delisa-sama/$(PACKAGE)
COVER_FILE ?= $(PACKAGE)-coverage.out

# Tools

.PHONY: tools
tools: ## Install all needed tools, e.g. for static checks
	@echo Installing tools from tools.go
	@cd tools; grep '_ "' tools.go | grep -o '"[^"]*"' | xargs -tI % go install %

# Main targets

all: test
.DEFAULT_GOAL := all

.PHONY: test
test: ## Run unit (short) tests
	go test -short ./... -coverprofile=$(COVER_FILE)
	go tool cover -func=$(COVER_FILE) | grep ^total

$(COVER_FILE):
	$(MAKE) test

.PHONY: cover
cover: $(COVER_FILE) ## Output coverage in human readable form in html
	go tool cover -html=$(COVER_FILE)
	rm -f $(COVER_FILE)

.PHONY: bench
bench: ## Run benchmarks
	go test ./... -short -bench=. -run="Benchmark*"

.PHONY: lint
lint: tools ## Check the project with lint
	golint -set_exit_status ./...

.PHONY: vet
vet: ## Check the project with vet
	go vet ./...

.PHONY: fmt
fmt: ## Run go fmt for the whole project
	test -z $$(for d in $$(go list -f {{.Dir}} ./...); do gofmt -e -l -w $$d/*.go; done)

.PHONY: imports
imports: tools ## Check and fix import section by import rules
	test -z $$(for d in $$(go list -f {{.Dir}} ./...); do goimports -e -l -local $(NAMESPACE) -w $$d/*.go; done)

.PHONY: code_style
code_style: ## Check code style issues in the project, only line length at the moment
	find . -name '*.go' -not -path "./.*" | grep -v _test.go | xargs -i sh -c "expand -t 4 {} | awk 'length>120' && expand -t 4 {} | awk 'length>120' | grep -v '@Param' |  grep -v 'json:' | grep -v 'gorm:' | wc -l | grep '^0$$' > /dev/null 2>&1 || echo {}"
	find . -name '*.go' -not -path "./.*" | grep -v _test.go | xargs expand -t 4 | awk 'length>120' | grep -v '@Param' | grep -v 'json:' | grep -v 'gorm:' | wc -l | grep '^0$$'

.PHONY: static_check
static_check: fmt imports vet lint code_style ## Run static checks (fmt, lint, imports, vet, ...) all over the project

.PHONY: check
check: static_check test ## Check project with static checks and unit tests

.PHONY: dependencies
dependencies: ## Manage go mod dependencies, beautify go.mod and go.sum files
	go mod tidy
	cd tools; go mod tidy

.PHONY: help
help: ## Print this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build_dir ?= build
branch ?= current
os ?= buster64
configureopt ?= --architecture amd64
makeopt ?= iso
buildsuffix ?= -amd64.iso

.PHONY: init
init:
	mkdir $(build_dir) || true

.PHONY: build
.ONESHELL:
build: init
	@set -e
	@echo "It's not like I'm building this specially for you or anything!"
	@./check-macos-build-env
	OS=$(os) BRANCH=$(branch) CONFIGUREOPT='$(configureopt)' MAKEOPT=$(makeopt) \
	vagrant up
	cd $(build_dir); \
	rsync -Lam --include='*$(buildsuffix)' --exclude='*' vagrant@10.1.1.254:/opt/vyos-build/build/ .

.PHONY: clean
clean:
	vagrant destroy -f

.PHONY: purge
purge: clean
	rm -rf $(build_dir)



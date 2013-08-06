TARGET ?= /kb/deployment
DEPLOY_RUNTIME = /kb/runtime
SERVICE = aux_store
SERVICE_DIR = $(TARGET)/services/$(SERVICE)

# to wrap scripts and deploy them to $(TARGET)/bin using tools in the dev_container
TOP_DIR = ../..
TOOLS_DIR = $(TOP_DIR)/tools
WRAP_PERL_TOOL = wrap_perl
WRAP_PERL_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_PERL_TOOL).sh
SRC_PERL = $(wildcard client/bin/*.pl)

.PHONY : test

all: deploy

deploy: deploy-client deploy-service

# deploy-all is depricted, consider removing it and using the deploy target
deploy-all: deploy-service deploy-client

deploy-service:
	git submodule init
	git submodule update
	sh install.sh $(SERVICE_DIR) $(TARGET) prod

deploy-service-test:
	git submodule init
	git submodule update
	sh install.sh $(SERVICE_DIR) $(TARGET) test

deploy-client: deploy-libs deploy-scripts deploy-docs
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib:$(TARGET)/lib/perl5 bash ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/plbin ; \
		$(WRAP_PERL_SCRIPT) "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done

deploy-libs:
	echo "deploy-libs not implemented yet"

deploy-scripts:
	echo "deploy-scripts not implemented yet"

deploy-docs: build-docs
	-mkdir -p $(SERVICE_DIR)/webroot
	# $(DEPLOY_RUNTIME)/bin/pod2html -t "Aux Store API" client/spec/c/admImpl.pm > $(SERVICE_DIR)/webroot/aux_store.html

build-docs:
	# mkdir -p client/spec/c
	# compile_typespec client/spec/adm.spec client/spec/c

# Test Section
TESTS = $(wildcard test/*.t)

test:
	# run each test
	for t in $(TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done


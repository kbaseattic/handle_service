TARGET ?= /kb/deployment
SERVICE = aux_store
SERVICE_DIR = $(TARGET)/services/$(SERVICE)

# to wrap scripts and deploy them to $(TARGET)/bin using tools in the dev_container
TOP_DIR = ../..
TOOLS_DIR = $(TOP_DIR)/tools
WRAP_PERL_TOOL = wrap_perl
WRAP_PERL_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_PERL_TOOL).sh
SRC_PERL = $(wildcard client/bin/*.pl)


all: deploy

deploy: deploy-client

deploy-all: deploy-service deploy-client

deploy-service:
	git submodule init
	git submodule update
	sh install.sh $(SERVICE_DIR) $(TARGET)/bin

deploy-client: deploy-docs
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

deploy-docs:
	-mkdir -p $(SERVICE_DIR)/webroot
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Aux Store API" client/spec/c/admImpl.pm > $(SERVICE_DIR)/webroot/aux_store.html

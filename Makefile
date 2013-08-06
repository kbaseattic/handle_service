TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))
LIB_PERL = $(wildcard Bio-KBase-Auth/lib/Bio/KBase/*.pm)

DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment
DEPLOY_PERL = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PERL))))

LIB_PATH = $(TARGET)/lib

all: deploy

deploy: deploy-libs deploy-scripts

deploy-libs:
	cd Bio-KBase-Auth; \
	mkdir -p $(KB_PERL_PATH); \
	$(DEPLOY_RUNTIME)/bin/perl ./Build.PL ; \
	$(DEPLOY_RUNTIME)/bin/perl ./Build installdeps --install_path lib=$(KB_PERL_PATH); \
	$(DEPLOY_RUNTIME)/bin/perl ./Build install --install_path lib=$(KB_PERL_PATH) 
	mkdir -p $(KB_PERL_PATH)/biokbase/auth; \
	touch $(KB_PERL_PATH)/biokbase/__init__.py; \
	touch $(KB_PERL_PATH)/biokbase/auth/__init__.py; \
	cp python-libs/auth_token.py $(KB_PERL_PATH)/biokbase/auth

deploy-scripts: deploy-perl-scripts deploy-python-scripts
	
deploy-perl-scripts:
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/plbin ; \
		$(WRAP_PERL_SCRIPT) "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done

deploy-python-scripts:
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PYTHON_PATH=$(TARGET)/lib ; \
	for src in $(SRC_PYTHON) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .py`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/pybin ; \
		$(WRAP_PYTHON_SCRIPT) "$(TARGET)/pybin/$$basefile" $(TARGET)/bin/$$base ; \
	done 

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


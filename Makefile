TARGET ?= /kb/deployment
SERVICE = aux_store
SERVICE_DIR = $(TARGET)/services/$(SERVICE)

all: deploy

deploy: deploy-services

deploy-services:
	git submodule init
	git submodule update
	sh install.sh $(SERVICE_DIR) $(TARGET)/bin
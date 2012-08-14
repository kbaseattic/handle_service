TARGET ?= /kb/deployment
SERVICE = shock
SERVICE_DIR = $(TARGET)/services/$(SERVICE)

all: deploy

deploy: deploy-services

deploy-services:
    git submodule init
	sh install.sh $(SERVICE_DIR)
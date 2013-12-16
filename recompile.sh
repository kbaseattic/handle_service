#!/bin/bash

SERVICE_SPEC=handle_service.spec
SERVICE_NAME=AbstractHandle
SERVICE_PORT=7109
SERVICE_DIR=handle_service
SERVICE_PSGI=${SERVICE_NAME}.psgi
SELF_URL=localhost:7019

compile_typespec \
        --psgi $SERVICE_PSGI  \
        --impl Bio::KBase::$SERVICE_NAME::${SERVICE_NAME}Impl \
        --service Bio::KBase::${SERVICE_NAME}::Service \
        --client Bio::KBase::${SERVICE_NAME}::Client   \
        --py biokbase/${SERVICE_NAME}/Client   \
        --js javascript/${SERVICE_NAME}/Client \
        --url $SELF_URL    \
        --scripts scripts  \
        --test test-script \
        $SERVICE_SPEC lib



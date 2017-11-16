FROM kbase/kb_perl:latest

# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH=develop

RUN apt-get update && \
    apt-get install -y default-libmysqlclient-dev default-mysql-client-core curl && \
    cpanm DBI DBD::mysql IPC::System::Simple Log::Log4perl && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives

COPY deployment /kb/deployment
ENV KB_DEPLOYMENT_CONFIG=/kb/deployment/conf/deployment.cfg

# The BUILD_DATE value seem to bust the docker cache when the timestamp changes, move to
# the end
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/kbase/handle_service.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      us.kbase.vcs-branch=$BRANCH \
      maintainer="Steve Chan sychan@lbl.gov"

EXPOSE 7109
ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]
CMD [ "-template", \
      "/kb/deployment/conf/.templates/deployment.cfg.templ:/kb/deployment/conf/deployment.cfg", \
      "starman", "--listen", ":7109", "/kb/deployment/lib/Bio/KBase/AbstractHandle/AbstractHandle.psgi" ]

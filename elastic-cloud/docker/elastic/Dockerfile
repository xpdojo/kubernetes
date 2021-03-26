#
# Elasticsearch Dockerfile
#
# https://github.com/dockerfile/elasticsearch
# https://www.elastic.co/downloads/past-releases#elasticsearch
# https://hub.docker.com/_/openjdk
#
# old version es
# FROM dockerfile/java:oracle-java8
# FROM openjdk:8-alpine3.8
# Unrecognized VM option 'UseParNewGC'
# Error: Could not create the Java Virtual Machine.
# Error: A fatal exception has occurred. Program will exit.
# => doesn't work with jdk 9+

# Pull base image.
FROM openjdk:11.0.10

ENV ES_TAG elasticsearch-7.11.2
ENV ARCH linux-x86_64

# Install Elasticsearch.
RUN \
  cd / && \
  wget https://artifacts.elastic.co/downloads/elasticsearch/$ES_TAG-$ARCH.tar.gz && \
  tar xvzf $ES_TAG-$ARCH.tar.gz && \
  rm -f $ES_TAG-$ARCH.tar.gz && \
  mv /$ES_TAG /elasticsearch

# Define mountable directories.
VOLUME ["/data"]

# Mount elasticsearch.yml config
ADD config/elasticsearch.yaml /elasticsearch/config/elasticsearch.yaml

# Define working directory.
WORKDIR /data

# Define default command.
# CMD ["/elasticsearch/bin/elasticsearch"]
ENTRYPOINT ["/elasticsearch/bin/elasticsearch"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300

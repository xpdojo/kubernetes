FROM python:3.7-slim-buster
COPY yna_crawler /yna_crawler

ENV JAVA_FOLDER java-se-8u41-ri
ENV JVM_ROOT /usr/lib/jvm
ENV JAVA_PKG_NAME openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz
ENV JAVA_TAR_GZ_URL https://download.java.net/openjdk/jdk8u41/ri/$JAVA_PKG_NAME

RUN apt-get update
RUN apt-get install -y apt-utils build-essential gcc
RUN apt-get install -y wget                                                               && \
  rm -rf /var/lib/apt/lists/*                                                             && \
  apt-get clean                                                                           && \
  apt-get autoremove                                                                      && \
  echo Downloading $JAVA_TAR_GZ_URL                                                       && \
  wget -q $JAVA_TAR_GZ_URL                                                                && \
  tar -xvf $JAVA_PKG_NAME                                                                 && \
  rm $JAVA_PKG_NAME                                                                       && \
  mkdir -p /usr/lib/jvm                                                                   && \
  mv ./$JAVA_FOLDER $JVM_ROOT                                                             && \
  update-alternatives --install /usr/bin/java java $JVM_ROOT/$JAVA_FOLDER/bin/java 1      && \
  update-alternatives --install /usr/bin/javac javac $JVM_ROOT/$JAVA_FOLDER/bin/javac 1   && \
  java -version

RUN pip3 install --requirement /yna_crawler/requirements.txt --verbose --no-cache-dir
ENTRYPOINT [ "python3", "/yna_crawler/yna_crawler/runner.py" ]

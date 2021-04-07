# FROM openjdk:8u282-jre-slim
# COPY --from=python:3.7-slim / /
FROM openjdk:11.0.4-jre-slim-buster
COPY --from=python:3.7.10-slim-buster / /

RUN pip3 install pip --upgrade
COPY yna_crawler /yna_crawler
RUN mkdir ${HOME}/.pip
RUN printf "[global]\nindex-url=http://ftp.daumkakao.com/pypi/simple\ntrusted-host=ftp.daumkakao.com" > ${HOME}/.pip/pip.conf
RUN pip3 install -I -r /yna_crawler/requirements.txt -v --no-cache-dir

ENTRYPOINT [ "python3", "/yna_crawler/yna_crawler/runner.py" ]

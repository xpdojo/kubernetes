FROM python:3.9.2-slim-buster
COPY yna_crawler /yna_crawler
RUN pip3 install -r /yna_crawler/requirements.txt
ENTRYPOINT [ "python3", "/yna_crawler/yna_crawler/runner.py" ]

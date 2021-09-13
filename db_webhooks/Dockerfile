FROM python:3.8.12-slim-bullseye

WORKDIR /usr/src/app

RUN apt-get update && apt-get install 

COPY conf/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY conf/config.yaml ./

COPY bin/docker-entrypoint.sh ./

ENTRYPOINT [ "/usr/src/app/docker-entrypoint.sh" ]

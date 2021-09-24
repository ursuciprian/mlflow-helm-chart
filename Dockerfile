FROM python:3.9-slim

LABEL maintainer="ursu.ciprian.petru@gmail.com" \
        name="MLFlow Tracking Server" \
        version="v1.20.2"

ARG MLFLOW_VERSION=1.20.2

USER root

RUN apt-get update -y && apt-get dist-upgrade -y
RUN apt-get install -y default-mysql-client && \
    apt-get install -y curl && \
    apt-get install netcat -y && \
    apt-get clean

RUN python -m pip install --upgrade pip && \
    pip install --upgrade wheel && \ 
    pip install --upgrade setuptools

RUN pip install PyMySQL==1.0.2 && \ 
    pip install psycopg2-binary==2.9.1 && \
    pip install mlflow==${MLFLOW_VERSION} && \
    pip install boto3 && \
    pip install gunicorn[gthread]

RUN useradd --create-home mlflow
WORKDIR /home/mlflow

EXPOSE 5000

USER mlflow

ENTRYPOINT ["mlflow", "server"]
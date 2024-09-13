FROM python:3.11-slim

RUN apt-get clean \
    && apt-get -y update

RUN apt-get -y install \
    nginx \
    python3-dev \
    build-essential

WORKDIR /app

COPY requirements.txt .

COPY server.py .

RUN pip install -r requirements.txt --src /usr/local/src

CMD ["python3", "server.py"]

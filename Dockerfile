FROM python:3.11-slim

LABEL Maintainer="beketx"

RUN apt-get update && apt-get install -y -q --no-install-recommends \
    python3-dev \
    gcc \
    ca-certificates \
    libpq-dev \
    wget \
    perl \
    #install Perl Database Interface
    libdbi-perl \
    bzip2 \
    libpq-dev \
    gnupg2 \
    libdbd-pg-perl \
    libwww-perl

WORKDIR /app
ENV PYTHONPATH="/app"

COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

COPY src src
WORKDIR "/app"

CMD ["python", "src/main.py"]
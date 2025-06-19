FROM jenkins/agent:latest-jdk17

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    docker.io \
    docker-compose \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-bcmath \
    php-mysql \
    php-zip \
    php-intl \
    php-gd \
    php-ffi \
    libffi-dev \
    unzip \
    curl \
    git \
    jq \
    mariadb-client \
    gnupg2 \
    lsb-release \
    ca-certificates \
    sudo \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g @angular/cli \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Docker group access
RUN usermod -aG docker jenkins

WORKDIR /home/jenkins
USER jenkins

FROM jenkins/agent:latest-jdk17

USER root
ENV DEBIAN_FRONTEND=noninteractive

# RUN apt-get update && apt-get install -y \
#     docker.io \
#     docker-compose \
#     php \
#     php-cli \
#     php-mbstring \
#     php-xml \
#     php-curl \
#     php-bcmath \
#     php-mysql \
#     php-zip \
#     php-intl \
#     php-gd \
#     php-ffi \
#     libffi-dev \
#     unzip \
#     curl \
#     git \
#     jq \
#     mariadb-client \
#     gnupg2 \
#     lsb-release \
#     ca-certificates \
#     sudo \
#   && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
#   && apt-get install -y nodejs \
#   && npm install -g @angular/cli \
#   && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*


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
    # === MISSING FOR PDOException: could not find driver (SQLite) ===
    php-sqlite3 \
    # This package provides the pdo_sqlite extension for PHP.
    # === RECOMMENDED FOR PLAYWRIGHT BROWSER DEPENDENCIES ===
    # These are common system libraries required by Chromium, Firefox, and WebKit
    # when running headlessly, which Playwright uses. Installing them here
    # makes your Playwright tests more reliable on the Jenkins agent.
    libnss3 \
    libasound2 \
    libgbm1 \
    libatk-bridge2.0-0 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libxss1 \
    libxtst6 \
    libdbus-glib-1-2 \
    libgconf-2-4 \
    libnotify4 \
    libappindicator1 \
    libappindicator3-1 \
    libxkbcommon0 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libgomp1 \
    # === EXISTING DEPENDENCIES (kept as is) ===
    libffi-dev \
    unzip \
    curl \
    git \
    jq \
    mariadb-client \
    gnupg2 \
    lsb-release \
    ca-certificates \
    # --
    xvfb \
    libxshmfence1 \
    fonts-liberation \
    # --
    sudo \
    # --
    chromium \
    # --
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

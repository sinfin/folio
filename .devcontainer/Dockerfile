FROM ruby:3.3.3-bookworm

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    CHROME_BIN=/usr/bin/chromium \
    CHROMEDRIVER_BIN=/usr/bin/chromedriver \
    NODE_OPTIONS=--openssl-legacy-provider

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    htop \
    nano \
    openssh-client \
    sudo \
    tmux \
    libpq-dev \
    libyaml-dev \
    postgresql-client \
    redis-tools \
    chromium \
    chromium-driver \
    exiftool \
    ffmpeg \
    ghostscript \
    giflib-tools \
    gifsicle \
    imagemagick \
    libcurl4 \
    libcurl4-openssl-dev \
    libdjvulibre-dev \
    libexif12 \
    libgif-dev \
    libgif7 \
    libheif-dev \
    libheif-examples \
    libheif1 \
    libimage-exiftool-perl \
    libjpeg-dev \
    libjpeg-progs \
    libjpeg-turbo-progs \
    liblcms2-2 \
    liblcms2-utils \
    libopenjp2-7 \
    libpng-dev \
    libpoppler-dev \
    libtiff-dev \
    libvips-dev \
    libvips-tools \
    libwebp-dev \
    libwmf-dev \
    optipng \
    webp \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && corepack enable \
  && corepack prepare yarn@1.22.22 --activate \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME} \
  && mkdir -p ${BUNDLE_PATH} \
  && chown -R ${USER_UID}:${USER_GID} ${BUNDLE_PATH}

RUN gem update --system --silent && gem install bundler --no-document

USER ${USERNAME}
WORKDIR /workspaces/folio

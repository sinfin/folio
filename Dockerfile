FROM ruby:2.6.6

# Update sources.list to use archived Debian repositories
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    postgresql-client \
    imagemagick \
    libvips-tools \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -qq && apt-get install -y yarn

# Set working directory
WORKDIR /app

# Install bundler version matching Gemfile.lock
RUN gem install bundler -v 2.2.24

# Copy Gemfile, Gemfile.lock, and gemspec
COPY Gemfile Gemfile.lock folio.gemspec ./
COPY lib/folio/version.rb ./lib/folio/

# Install gems with specific build configurations from your environment
RUN bundle config set --local build.nio4r '--with-cflags=-Wno-incompatible-pointer-types' \
    && bundle config set --local build.nokogiri '--use-system-libraries' \
    && bundle config set --local build.puma '--with-cflags=-Wno-error=incompatible-pointer-types' \
    && bundle config set --local build.sqlite3 '--with-cflags=-Wno-error=incompatible-pointer-types' \
    && bundle install

# Copy the rest of the application
COPY . .

# Precompile assets (optional, can be done at runtime)
# RUN bundle exec rails assets:precompile

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

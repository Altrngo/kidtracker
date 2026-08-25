# Dockerfile
# Build multi-stage pour une image de production légère

ARG RUBY_VERSION=3.4.8
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Dépendances système nécessaires à l'exécution
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq-dev \
      curl \
      libjemalloc2 && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ─────────────────────────────────────────────────────────────
# Stage build : compile les gems et assets
# ─────────────────────────────────────────────────────────────
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Précompile assets — nécessite une SECRET_KEY_BASE bidon pour le build
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ─────────────────────────────────────────────────────────────
# Stage final : image légère sans outils de build
# ─────────────────────────────────────────────────────────────
FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Crée un user non-root pour exécuter l'app
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]

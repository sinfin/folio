#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/folio

echo "==> Bootstrapping Folio devcontainer"

if [ -f .devcontainer/tmp/tmux.conf ]; then
  echo "==> Installing host tmux config"
  cp .devcontainer/tmp/tmux.conf "$HOME/.tmux.conf"
  rm .devcontainer/tmp/tmux.conf
fi

if [ ! -f test/dummy/.env ] && [ -f test/dummy/.env.sample ]; then
  echo "==> Copying test/dummy/.env.sample -> test/dummy/.env"
  cp test/dummy/.env.sample test/dummy/.env
fi

echo "==> bundle install"
bundle config set --local path "${BUNDLE_PATH}"
bundle install --jobs="$(nproc)"

echo "==> rake app:folio:prepare_dummy_app (copies Redactor assets)"
bundle exec rake app:folio:prepare_dummy_app || echo "!! prepare_dummy_app returned non-zero — non-fatal, continuing"

echo "==> rails db:create (idempotent)"
bundle exec rails db:create 2>&1 | grep -v "already exists" || true

echo "==> rails db:migrate"
bundle exec rails db:migrate

if bundle exec rails runner "exit(Folio::User.count.zero? ? 0 : 1)" 2>/dev/null; then
  echo "==> Empty DB detected — running db:seed"
  bundle exec rails db:seed || echo "!! db:seed failed — run manually later if needed"
else
  echo "==> DB already has users — skipping db:seed"
fi

if [ -d react ] && [ -f react/package.json ]; then
  echo "==> react/: yarn install"
  (cd react && yarn install --frozen-lockfile) || echo "!! react yarn install failed — retry with 'cd react && yarn install'"
fi

if [ -f package.json ]; then
  echo "==> root: npm install (for standardjs)"
  npm install --no-audit --no-fund || echo "!! root npm install failed — retry manually"
fi

cat <<'EOF'

==> Bootstrap complete.

Next steps (run inside the container):
  bundle exec rails s -b 0.0.0.0 -p 3000     # Rails at http://dummy.localhost:3000
  bundle exec sidekiq                         # background jobs (separate terminal)
  cd react && yarn start                      # React dev server at http://localhost:3001
  bundle exec guard                           # live rubocop / slim-lint / standardjs

Login: test@test.test / test@test.test  (see lib/tasks/folio_tasks.rake).
EOF

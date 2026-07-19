# Runs the app against the dev backend with dev-environment SDK keys.
#
# These values are safe to commit: Sentry DSNs and PostHog project API keys
# are both designed to be public/client-embeddable (they only allow sending
# events, not reading data) - same as how they end up baked into the
# compiled app binary either way. Real secrets (JWT signing keys, DB
# passwords, etc.) never belong in a Flutter --dart-define.

flutter run `
  --dart-define=ENV=development `
  --dart-define=API_BASE_URL=https://dev-api.docwellness.fit `
  --dart-define=SENTRY_DSN=https://f4c9793d3f9b075811f05176fab60f98@o4511762128896000.ingest.de.sentry.io/4511762136825936 `
  --dart-define=POSTHOG_API_KEY= `
  --dart-define=POSTHOG_HOST=https://us.i.posthog.com

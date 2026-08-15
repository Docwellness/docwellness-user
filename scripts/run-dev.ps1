# Runs the app against the dev backend with dev-environment SDK keys.
#
# These values are safe to commit: Sentry DSNs and PostHog project API keys
# are both designed to be public/client-embeddable (they only allow sending
# events, not reading arbitrary data) - same as how they end up baked into
# the compiled app binary either way. Real secrets (JWT signing keys, DB
# passwords, Supabase's service role key, etc.) never belong in a Flutter
# --dart-define - the app no longer talks to Supabase directly at all
# (every auth operation goes through the backend's /auth/* endpoints), so
# there's no Supabase key here anymore either.

flutter run `
  --dart-define=ENV=development `
  --dart-define=API_BASE_URL=https://dev-api.docwellness.fit `
  --dart-define=SENTRY_DSN=https://f4c9793d3f9b075811f05176fab60f98@o4511762128896000.ingest.de.sentry.io/4511762136825936 `
  --dart-define=POSTHOG_API_KEY=phc_r36BW82kcdGPitJRk34vb2fNnxMamUVaHRcBPzeebVMe `
  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com

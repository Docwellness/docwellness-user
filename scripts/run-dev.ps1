# Runs the app against the dev backend with dev-environment SDK keys.
#
# These values are safe to commit: Sentry DSNs, PostHog project API keys,
# and Supabase's publishable (anon) key are all designed to be public/
# client-embeddable (they only allow sending events / the actions RLS
# policies permit, not reading arbitrary data) - same as how they end up
# baked into the compiled app binary either way. Real secrets (JWT signing
# keys, DB passwords, Supabase's *service role* key, etc.) never belong in
# a Flutter --dart-define.

flutter run `
  --dart-define=ENV=development `
  --dart-define=API_BASE_URL=https://dev-api.docwellness.fit `
  --dart-define=SENTRY_DSN=https://f4c9793d3f9b075811f05176fab60f98@o4511762128896000.ingest.de.sentry.io/4511762136825936 `
  --dart-define=POSTHOG_API_KEY=phc_r36BW82kcdGPitJRk34vb2fNnxMamUVaHRcBPzeebVMe `
  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com `
  --dart-define=SUPABASE_URL=https://ovflhhhtwrjthnyrnaoo.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_FmRYCR40VTVGDsHxK7Z9jQ_67UZ-t-o

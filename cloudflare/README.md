# Domain migration rules

`domain-redirects.json` is a deployment manifest for Cloudflare Dashboard →
Rules → Redirect Rules → Single Redirects. Create each entry as a **Wildcard
pattern** rule in the zone named by `zone`.

For every rule:

- Request URL: copy `request_url`.
- Target URL: copy `target_url`.
- Status: `301`.
- Preserve query string: enabled.

The old hostname and `www` DNS records must remain proxied through Cloudflare.
Do not remove `cfmoto.com.az` after the migration; keeping its redirect active
preserves old links and search authority.

Create `account_bulk_redirect` as an account-level **Bulk Redirect**:

- Source URL: `https://cfmoto-azerbaijan.pages.dev`
- Target URL: `https://cfmoto.az`
- Status: `301`
- Enable Preserve query string, Subpath matching, Preserve path suffix, and
  Include subdomains.

This prevents the production and preview `*.pages.dev` hostnames from remaining
available as duplicate copies of the canonical site.

The deployable `_redirects` file handles former **paths** after a request reaches
the Pages project. Cloudflare Pages does not support domain-level matching in
`_redirects`, so the three hostname rules above must be created at zone level.

## HSTS on apex and www

The Pages `_headers` file adds `Strict-Transport-Security: max-age=31536000` to
responses served by the project. The `www.cfmoto.az` Single Redirect runs at the
zone edge before Pages headers are applied, so configure the same one-year HSTS
policy in Cloudflare **SSL/TLS → Edge Certificates** (or an equivalent response
header Transform Rule). Keep **Include subdomains** and **Preload** disabled
until every subdomain has been audited for permanent HTTPS support.

After deployment, confirm that both the apex response and the `www` redirect
include `Strict-Transport-Security`.

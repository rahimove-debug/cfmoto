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

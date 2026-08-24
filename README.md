# CFMOTO Azerbaijan

CFMOTO Azerbaijan üçün statik sayt, SEO emalı və Cloudflare Pages build paketi.

## Cloudflare Pages

- Production branch: `main`
- Framework preset: `None`
- Build command: `ruby scripts/build_cloudflare.rb`
- Build output directory: `dist`

Build skripti SEO auditini işə salır və yalnız ictimai sayt fayllarını `dist/` qovluğuna köçürür. GitHub Actions əsas saytdan yeni versiyanı idxal edərkən SEO düzəlişlərini yenidən tətbiq edir və Cloudflare paketini yoxlayır.

## Lokal yoxlama

```sh
ruby scripts/apply_seo.rb
ruby scripts/audit_seo.rb
ruby scripts/build_cloudflare.rb
python3 -m http.server 4173 --directory dist
```

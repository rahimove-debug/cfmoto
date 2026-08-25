# CFMOTO Azerbaijan

CFMOTO Azerbaijan üçün statik sayt, SEO emalı və Cloudflare Pages build paketi.

## Cloudflare Pages

- Production branch: `main`
- Framework preset: `None`
- Build command: `ruby scripts/build_cloudflare.rb`
- Build output directory: `dist`

Build skripti SEO auditini işə salır və yalnız ictimai sayt fayllarını `dist/` qovluğuna köçürür. GitHub Actions əsas saytdan yeni versiyanı idxal edərkən SEO düzəlişlərini yenidən tətbiq edir və Cloudflare paketini yoxlayır.

Build zamanı beş yüngül SEO məlumat səhifəsi də yaradılır:

- `/kredit`
- `/servis`
- `/zemanet`
- `/ehtiyat-hisseleri`
- `/model-muqayisesi`

Sayt ümumilikdə 53 canonical səhifə və `404.html` ilə birlikdə 54 HTML faylı yayımlayır. Ana səhifənin model kartları üçün `models/cards/` daxilində 680 px WebP variantları istifadə olunur; model səhifələrinin ilkin məhsul şəkilləri isə üçüncü tərəf hostu əvəzinə yerli `models/` fayllarından yüklənir.

Əsas domen `https://cfmoto.az` olaraq build mənbəyində sabitlənib. Build zamanı
köhnə `cfmoto.com.az`, `www` və preview originləri canonical, Open Graph,
Twitter, sitemap, robots və JSON-LD məlumatlarından təmizlənir. Köhnə səhifə
yolları üçün 301 qaydaları `_redirects` faylına yaradılır; domen səviyyəli
Cloudflare qaydaları [cloudflare/README.md](cloudflare/README.md) faylında verilib.

## Lokal yoxlama

```sh
ruby scripts/build_cloudflare.rb
python3 -m http.server 4173 --directory dist
```

Model şəkilləri yenilənəndə Pillow quraşdırılmış Python mühitində kart variantlarını yenidən yaratmaq olar:

```sh
python3 scripts/generate_card_images.py
```

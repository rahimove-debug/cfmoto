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

Məhsulları, qiymətləri, izahlı mətni və FAQ bölməsini ehtiva edən ayrıca kateqoriya səhifələri yaradılır:

- `/motosiklet/` — 29 motosiklet
- `/kvadrosikl/` — 9 ATV
- `/buggy/` — 9 buggy/UTV

Köhnə `/motosi%CC%87klet` yolu `301` statusu ilə `/motosiklet/` səhifəsinə yönləndirilir. Kateqoriya URL-ləri ana səhifəyə yönləndirilmir.

Saytın tam rus dili versiyası `/ru/` altında yaradılır. Buraya 47 model, beş məlumat səhifəsi və üç kateqoriya daxildir. Hər AZ/RU cütü öz canonical URL-inə, qarşılıqlı `hreflang="az"`, `hreflang="ru"` və `x-default` işarələrinə malikdir. Sitemap 112 canonical URL saxlayır.

Sayt `404.html` daxil olmaqla 113 HTML faylı yayımlayır. Ana səhifənin model kartları və model mega-menyusu üçün `models/cards/` daxilində 680 px WebP variantları istifadə olunur; model səhifələrinin ilkin məhsul şəkilləri isə üçüncü tərəf hostu əvəzinə yerli `models/` fayllarından yüklənir. Dəyişən JavaScript və CSS assetləri keşlənmiş köhnə kodla qarışmaması üçün versiyalı URL-lərlə yayımlanır; rus səhifələri hidratasiya uyğunluğu üçün ayrı rus dili asset paketlərindən istifadə edir.

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

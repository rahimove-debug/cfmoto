#!/usr/bin/env ruby
require "json"

ROOT = File.expand_path("..", __dir__)
STYLESHEET = '<link rel="stylesheet" href="/assets/confirmed-pricing-v1.css"/>'

AZ_CAMPAIGN_LABEL = "Kampaniya qiyməti"
RU_CAMPAIGN_LABEL = "Акционная цена"
AZ_ACCESSIBLE_PRICE = "Z10-4 üçün siyahı qiyməti 49,900 AZN, kampaniya qiyməti 47,900 AZN-dir. Qənaət 2,000 AZN təşkil edir."
RU_ACCESSIBLE_PRICE = "Цена Z10-4 по прайс-листу — 49,900 AZN, акционная цена — 47,900 AZN. Экономия составляет 2,000 AZN."

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def write_utf8(path, content)
  File.write(path, content, mode: "w", encoding: "UTF-8")
end

def replace_required!(content, before, after, label)
  return false if content.include?(after)
  abort "#{label} anchor not found" unless content.include?(before)

  content.gsub!(before, after)
  true
end

def replace_page_metadata!(html, title:, description:)
  old_title = html[/<title>(.*?)<\/title>/m, 1]
  old_description = html[/<meta name="description" content="([^"]*)"\/>/, 1]
  abort "Page title missing" unless old_title
  abort "Page description missing" unless old_description

  html.gsub!(old_title, title)
  html.gsub!(old_description, description)
end

def transform_z10_rsc_price!(html, language)
  replacements = 0
  existing = 0
  pattern = /(self\.__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/

  html = html.gsub(pattern) do
    before = Regexp.last_match(1)
    encoded = Regexp.last_match(2)
    after = Regexp.last_match(3)
    chunk = JSON.parse(encoded)

    lines = chunk.split("\n", -1).map do |line|
      match = line.match(/\A([0-9a-f]+:)([\[{].*)\z/)
      next line unless match

      begin
        node = JSON.parse(match[2])
      rescue JSON::ParserError
        next line
      end

      visit = lambda do |value|
        if value.is_a?(Array)
          if value[0] == "$" && value[1] == "div" && value[3].is_a?(Hash) && value[3]["className"] == "product-price"
            ru = language == :ru
            value[3]["className"] = "product-price is-campaign"
            value[3]["aria-label"] = ru ? RU_ACCESSIBLE_PRICE : AZ_ACCESSIBLE_PRICE
            value[3]["children"] = [
              ["$", "small", nil, { "children" => ru ? RU_CAMPAIGN_LABEL : AZ_CAMPAIGN_LABEL }],
              ["$", "del", nil, { "children" => "49,900 AZN" }],
              ["$", "strong", nil, { "children" => "47,900 AZN" }],
              ["$", "span", nil, { "className" => "campaign-saving", "children" => ru ? "Экономия 2,000 AZN" : "2,000 AZN qənaət" }]
            ]
            replacements += 1
          elsif value[0] == "$" && value[1] == "div" && value[3].is_a?(Hash) && value[3]["className"] == "product-price is-campaign"
            expected_label = language == :ru ? RU_CAMPAIGN_LABEL : AZ_CAMPAIGN_LABEL
            expected_accessible = language == :ru ? RU_ACCESSIBLE_PRICE : AZ_ACCESSIBLE_PRICE
            children = value[3]["children"]
            valid = value[3]["aria-label"] == expected_accessible &&
              children.is_a?(Array) &&
              children.dig(0, 3, "children") == expected_label &&
              children.dig(1, 3, "children") == "49,900 AZN" &&
              children.dig(2, 3, "children") == "47,900 AZN"
            abort "#{language}: malformed existing Z10-4 RSC campaign price" unless valid
            existing += 1
          end
          value.each { |child| visit.call(child) }
        elsif value.is_a?(Hash)
          value.each_value { |child| visit.call(child) }
        end
      end
      visit.call(node)
      "#{match[1]}#{JSON.generate(node)}"
    end

    encoded_chunk = JSON.generate(lines.join("\n")).gsub("<", "\\u003c")
    "#{before}#{encoded_chunk}#{after}"
  end

  count = replacements + existing
  abort "#{language}: expected one Z10-4 RSC price block, found #{count}" unless count == 1
  html
end

def campaign_product_price(language)
  if language == :ru
    %(<div class="product-price is-campaign" aria-label="#{RU_ACCESSIBLE_PRICE}"><small>#{RU_CAMPAIGN_LABEL}</small><del>49,900 AZN</del><strong>47,900 AZN</strong><span class="campaign-saving">Экономия 2,000 AZN</span></div>)
  else
    %(<div class="product-price is-campaign" aria-label="#{AZ_ACCESSIBLE_PRICE}"><small>#{AZ_CAMPAIGN_LABEL}</small><del>49,900 AZN</del><strong>47,900 AZN</strong><span class="campaign-saving">2,000 AZN qənaət</span></div>)
  end
end

# Add list-price metadata to the shared catalog and render it in both the
# mega-menu and homepage React components. The transactional price remains
# 47,900 AZN, which is what calculators and Product Offer schema must use.
Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js")).each do |path|
  content = read_utf8(path)
  next unless content.include?('slug:`z10-4`') || content.include?('slug:`cforce-c5`')

  if content.include?('slug:`cforce-c5`')
    content = content.gsub(/\{slug:`cforce-c5`,[^{}]*\}/) do |record|
      if record.include?('badge:`GEN⁴`')
        record
      elsif record.match?(/badge:`(?:Yeni|Новинка)`/)
        record.sub(/badge:`(?:Yeni|Новинка)`/, 'badge:`GEN⁴`')
      else
        abort "C5 badge anchor missing in #{File.basename(path)}"
      end
    end
  end

  unless content.include?('slug:`z10-4`')
    write_utf8(path, content)
    next
  end

  unless content.include?('price:47900,listPrice:49900,campaign:!0,image:`/models/z10-4.webp`')
    changed = content.sub!(
      'price:47900,image:`/models/z10-4.webp`',
      'price:47900,listPrice:49900,campaign:!0,image:`/models/z10-4.webp`'
    )
    abort "Z10-4 catalog anchor missing in #{File.basename(path)}" unless changed
  end

  russian = content.include?("Уточнить цену")
  old_render = if russian
    '(0,u.jsxs)(`p`,{children:[e.price===null?`Уточнить цену`:`${l(e.price)} AZN${e.vatIncluded?` · НДС включён`:``}`,` `,(0,u.jsx)(`b`,{children:`↗︎`})]})'
  else
    '(0,u.jsxs)(`p`,{children:[e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`,` `,(0,u.jsx)(`b`,{children:`↗︎`})]})'
  end
  new_render = if russian
    '(0,u.jsxs)(`p`,{className:e.listPrice?`campaign-menu-price`:void 0,children:[e.listPrice&&(0,u.jsx)(`del`,{children:`${l(e.listPrice)} AZN`}),e.listPrice&&(0,u.jsx)(`span`,{children:`${l(e.price)} AZN · Акция`}),!e.listPrice&&(e.price===null?`Уточнить цену`:`${l(e.price)} AZN${e.vatIncluded?` · НДС включён`:``}`),` `,(0,u.jsx)(`b`,{children:`↗︎`})]})'
  else
    '(0,u.jsxs)(`p`,{className:e.listPrice?`campaign-menu-price`:void 0,children:[e.listPrice&&(0,u.jsx)(`del`,{children:`${l(e.listPrice)} AZN`}),e.listPrice&&(0,u.jsx)(`span`,{children:`${l(e.price)} AZN · Kampaniya`}),!e.listPrice&&(e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`),` `,(0,u.jsx)(`b`,{children:`↗︎`})]})'
  end
  replace_required!(content, old_render, new_render, "Mega-menu campaign rendering in #{File.basename(path)}")
  write_utf8(path, content)
end

Dir.glob(File.join(ROOT, "assets", "page-Cfmoto*.js")).each do |path|
  content = read_utf8(path)
  next unless content.include?('className:`model-price`') && content.include?('slug:`z10-4`')

  russian = content.include?('children:`Цена`')
  old_card = if russian
    '(0,c.jsxs)(`div`,{className:`model-price`,children:[(0,c.jsx)(`small`,{children:`Цена`}),(0,c.jsx)(`strong`,{children:e.price===null?`Уточнить`:`${o(e.price)} AZN${e.vatIncluded?` · НДС включён`:``}`})]})'
  else
    '(0,c.jsxs)(`div`,{className:`model-price`,children:[(0,c.jsx)(`small`,{children:`Qiymət`}),(0,c.jsx)(`strong`,{children:e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`})]})'
  end
  new_card = if russian
    '(0,c.jsxs)(`div`,{className:`model-price ${e.listPrice?`is-campaign`:``}`,children:[(0,c.jsx)(`small`,{children:e.listPrice?`Акционная цена`:`Цена`}),e.listPrice&&(0,c.jsx)(`del`,{children:`${o(e.listPrice)} AZN`}),(0,c.jsx)(`strong`,{children:e.price===null?`Уточнить`:`${o(e.price)} AZN${e.vatIncluded?` · НДС включён`:``}`}),e.listPrice&&(0,c.jsx)(`span`,{className:`campaign-saving`,children:`Экономия ${o(e.listPrice-e.price)} AZN`})]})'
  else
    '(0,c.jsxs)(`div`,{className:`model-price ${e.listPrice?`is-campaign`:``}`,children:[(0,c.jsx)(`small`,{children:e.listPrice?`Kampaniya qiyməti`:`Qiymət`}),e.listPrice&&(0,c.jsx)(`del`,{children:`${o(e.listPrice)} AZN`}),(0,c.jsx)(`strong`,{children:e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`}),e.listPrice&&(0,c.jsx)(`span`,{className:`campaign-saving`,children:`${o(e.listPrice-e.price)} AZN qənaət`})]})'
  end
  replace_required!(content, old_card, new_card, "Homepage campaign card in #{File.basename(path)}")

  old_hero = if russian
    '(0,c.jsxs)(`span`,{children:[(0,c.jsx)(`small`,{children:`Начальная цена`}),(0,c.jsx)(`strong`,{children:i?.price?`${o(i.price)} AZN`:`Уточнить`})]})'
  else
    '(0,c.jsxs)(`span`,{children:[(0,c.jsx)(`small`,{children:`Başlanğıc qiymət`}),(0,c.jsx)(`strong`,{children:i?.price?`${o(i.price)} AZN`:`Dəqiqləşdirin`})]})'
  end
  new_hero = if russian
    '(0,c.jsxs)(`span`,{className:i?.listPrice?`is-campaign`:void 0,children:[(0,c.jsx)(`small`,{children:i?.listPrice?`Акционная цена`:`Начальная цена`}),i?.listPrice&&(0,c.jsx)(`del`,{children:`${o(i.listPrice)} AZN`}),(0,c.jsx)(`strong`,{children:i?.price?`${o(i.price)} AZN`:`Уточнить`})]})'
  else
    '(0,c.jsxs)(`span`,{className:i?.listPrice?`is-campaign`:void 0,children:[(0,c.jsx)(`small`,{children:i?.listPrice?`Kampaniya qiyməti`:`Başlanğıc qiymət`}),i?.listPrice&&(0,c.jsx)(`del`,{children:`${o(i.listPrice)} AZN`}),(0,c.jsx)(`strong`,{children:i?.price?`${o(i.price)} AZN`:`Dəqiqləşdirin`})]})'
  end
  replace_required!(content, old_hero, new_hero, "Homepage featured campaign price in #{File.basename(path)}")
  write_utf8(path, content)
end

html_paths = Dir.glob(File.join(ROOT, "**", "*.html")).reject do |path|
  path.include?("/dist/") || path.include?("/aksesuar-konfiquratoru/")
end

html_paths.each do |path|
  html = read_utf8(path)
  html.sub!("</head>", "#{STYLESHEET}</head>") unless html.include?(STYLESHEET)
  russian = path.include?("/ru/")

  html = html.gsub(%r{<a\b[^>]*href="/(?:ru/)?model/cforce-c5/?".*?</a>}m) do |card|
    card.gsub(/<span class="badge">(?:Yeni|Новинка)<\/span>/, '<span class="badge">GEN⁴</span>')
  end

  old_menu = '<h3>Z10-4</h3><p>47,900 AZN<!-- --> <b>↗︎</b></p>'
  new_menu = if russian
    '<h3>Z10-4</h3><p class="campaign-menu-price"><del>49,900 AZN</del><span>47,900 AZN · Акция</span><!-- --> <b>↗︎</b></p>'
  else
    '<h3>Z10-4</h3><p class="campaign-menu-price"><del>49,900 AZN</del><span>47,900 AZN · Kampaniya</span><!-- --> <b>↗︎</b></p>'
  end
  html.gsub!(old_menu, new_menu)
  write_utf8(path, html)
end

# Homepage card and featured price.
{
  File.join(ROOT, "index.html") => {
    card_before: '<div class="model-price"><small>Qiymət</small><strong>47,900 AZN</strong></div>',
    card_after: '<div class="model-price is-campaign"><small>Kampaniya qiyməti</small><del>49,900 AZN</del><strong>47,900 AZN</strong><span class="campaign-saving">2,000 AZN qənaət</span></div>',
    hero_before: '<span><small>Başlanğıc qiymət</small><strong>47,900 AZN</strong></span>',
    hero_after: '<span class="is-campaign"><small>Kampaniya qiyməti</small><del>49,900 AZN</del><strong>47,900 AZN</strong></span>'
  },
  File.join(ROOT, "ru", "index.html") => {
    card_before: '<div class="model-price"><small>Цена</small><strong>47,900 AZN</strong></div>',
    card_after: '<div class="model-price is-campaign"><small>Акционная цена</small><del>49,900 AZN</del><strong>47,900 AZN</strong><span class="campaign-saving">Экономия 2,000 AZN</span></div>',
    hero_before: '<span><small>Начальная цена</small><strong>47,900 AZN</strong></span>',
    hero_after: '<span class="is-campaign"><small>Акционная цена</small><del>49,900 AZN</del><strong>47,900 AZN</strong></span>'
  }
}.each do |path, copy|
  html = read_utf8(path)
  replace_required!(html, copy[:card_before], copy[:card_after], "#{path} Z10-4 card")
  replace_required!(html, copy[:hero_before], copy[:hero_after], "#{path} Z10-4 featured price")
  write_utf8(path, html)
end

# Category pages.
{
  File.join(ROOT, "buggy", "index.html") => [
    '<h2>Z10-4</h2><p>Buggy · 1000 cc</p><strong>47,900 AZN</strong>',
    '<h2>Z10-4</h2><p>Buggy · 1000 cc</p><div class="category-campaign-price" aria-label="Z10-4: siyahı qiyməti 49,900 AZN, kampaniya qiyməti 47,900 AZN"><small>Kampaniya</small><del>49,900 AZN</del><strong>47,900 AZN</strong></div>'
  ],
  File.join(ROOT, "ru", "buggy", "index.html") => [
    '<h2>Z10-4</h2><p>Багги · 1000 см³</p><strong>47,900 AZN</strong>',
    '<h2>Z10-4</h2><p>Багги · 1000 см³</p><div class="category-campaign-price" aria-label="Z10-4: цена по прайс-листу 49,900 AZN, акционная цена 47,900 AZN"><small>Акция</small><del>49,900 AZN</del><strong>47,900 AZN</strong></div>'
  ]
}.each do |path, (before, after)|
  html = read_utf8(path)
  replace_required!(html, before, after, "#{path} Z10-4 category card")
  write_utf8(path, html)
end

# Make the platform benefit explicit at the ATV category decision point as
# well as on the model page. The orange GEN⁴ badge remains the concise home and
# mega-menu cue.
{
  File.join(ROOT, "kvadrosikl", "index.html") => [
    '<h2>CFORCE C5</h2><p>Kvadrosikl · 500 cc</p>',
    '<h2>CFORCE C5</h2><p>Kvadrosikl · 500 cc · Yeni GEN⁴ platforması</p>'
  ],
  File.join(ROOT, "ru", "kvadrocikly", "index.html") => [
    '<h2>CFORCE C5</h2><p>Квадроцикл · 500 см³</p>',
    '<h2>CFORCE C5</h2><p>Квадроцикл · 500 см³ · Новая платформа GEN⁴</p>'
  ]
}.each do |path, (before, after)|
  html = read_utf8(path)
  replace_required!(html, before, after, "#{path} C5 GEN4 category positioning")
  write_utf8(path, html)
end

# Comparison pages retain the campaign price as the financing basis.
{
  File.join(ROOT, "model-muqayisesi", "index.html") => [
    '<th scope="row"><a href="/model/z10-4/">Z10-4</a></th><td>Buggy · Sport SSV · 1000 cc</td><td>47,900 AZN</td>',
    '<th scope="row"><a href="/model/z10-4/">Z10-4</a></th><td>Buggy · Sport SSV · 1000 cc</td><td class="campaign-table-price"><small>Kampaniya</small><del>49,900 AZN</del><strong>47,900 AZN</strong></td>'
  ],
  File.join(ROOT, "ru", "sravnenie-modeley", "index.html") => [
    '<th scope="row"><a href="/ru/model/z10-4/">Z10-4</a></th><td>Багги · Спортивный SSV · 1000 см³</td><td>47,900 AZN</td>',
    '<th scope="row"><a href="/ru/model/z10-4/">Z10-4</a></th><td>Багги · Спортивный SSV · 1000 см³</td><td class="campaign-table-price"><small>Акция</small><del>49,900 AZN</del><strong>47,900 AZN</strong></td>'
  ]
}.each do |path, (before, after)|
  html = read_utf8(path)
  replace_required!(html, before, after, "#{path} Z10-4 comparison row")
  write_utf8(path, html)
end

# Product detail pages and search/social metadata.
{
  File.join(ROOT, "model", "z10-4", "index.html") => {
    language: :az,
    before: '<div class="product-price"><small>Nağd satış qiyməti</small><strong>47,900 AZN</strong></div>',
    title: "Z10-4 | CFMOTO Azerbaijan",
    description: "CFMOTO Z10-4: siyahı qiyməti 49,900 AZN, kampaniya qiyməti 47,900 AZN. 998 cc turbo mühərrik və dörd nəfərlik kokpit."
  },
  File.join(ROOT, "ru", "model", "z10-4", "index.html") => {
    language: :ru,
    before: '<div class="product-price"><small>Цена при оплате наличными</small><strong>47,900 AZN</strong></div>',
    title: "Z10-4 | CFMOTO Азербайджан",
    description: "CFMOTO Z10-4: цена по прайс-листу 49,900 AZN, акционная цена 47,900 AZN. Турбодвигатель 998 см³ и четырёхместный кокпит."
  }
}.each do |path, config|
  html = read_utf8(path)
  replace_required!(html, config[:before], campaign_product_price(config[:language]), "#{path} campaign product price")
  html = transform_z10_rsc_price!(html, config[:language])
  replace_page_metadata!(html, title: config[:title], description: config[:description])
  write_utf8(path, html)
end

{
  File.join(ROOT, "model", "cforce-c5", "index.html") => [
    "CFMOTO CFORCE C5 GEN⁴ — qiymət və xüsusiyyətlər",
    "Yeni GEN⁴ platformalı CFORCE C5: 498,6 cc mühərrik, 39 a.g., 2WD/4WD və 612 kq yedəkləmə. Nağd qiymət 13,900 AZN."
  ],
  File.join(ROOT, "ru", "model", "cforce-c5", "index.html") => [
    "CFMOTO CFORCE C5 GEN⁴ — цена и характеристики",
    "CFORCE C5 на новой платформе GEN⁴: двигатель 498,6 см³, 39 л. с., 2WD/4WD и буксировка до 612 кг. Цена 13,900 AZN."
  ]
}.each do |path, (title, description)|
  html = read_utf8(path)
  replace_page_metadata!(html, title: title, description: description)
  write_utf8(path, html)
end

# Keep the already-published Z10 story aligned with the approved campaign.
news_path = File.join(ROOT, "xeberler", "z10-z10-4-turbo-performans-azerbaycanda", "index.html")
news = read_utf8(news_path)
replace_required!(
  news,
  "CFMOTO Azerbaijan-da göstərilən aktual nağd qiymətlər müvafiq olaraq 45,900 AZN və 47,900 AZN-dir.",
  "CFMOTO Azerbaijan-da Z10 üçün aktual nağd qiymət 45,900 AZN-dir; Z10-4 isə 49,900 AZN siyahı qiymətinə qarşı 47,900 AZN kampaniya qiyməti ilə təqdim olunur.",
  "Z10 article lead campaign copy"
)
replace_required!(
  news,
  '<div class="compare-row"><strong>Nağd qiymət</strong><span>45,900 AZN</span><span>47,900 AZN</span></div>',
  '<div class="compare-row"><strong>Qiymət</strong><span>45,900 AZN</span><span class="campaign-table-price"><small>Kampaniya</small><del>49,900 AZN</del><strong>47,900 AZN</strong></span></div>',
  "Z10 article comparison campaign price"
)
replace_required!(
  news,
  "Z10 üçün 45,900 AZN, Z10-4 üçün isə 47,900 AZN nağd qiymət göstərilir.",
  "Z10 üçün 45,900 AZN nağd qiymət, Z10-4 üçün isə 49,900 AZN siyahı qiymətinə qarşı 47,900 AZN kampaniya qiyməti göstərilir.",
  "Z10 article body campaign copy"
)
replace_required!(
  news,
  '<div class="fact-row"><span>Nağd qiymət</span><strong>45,900 / 47,900 AZN</strong></div>',
  '<div class="fact-row"><span>Qiymət</span><strong>Z10 45,900 · Z10-4 kampaniya 47,900 AZN</strong></div>',
  "Z10 article facts campaign copy"
)
write_utf8(news_path, news)

puts "Confirmed price presentation applied: C5 GEN⁴ positioning and Z10-4 list/campaign pricing"

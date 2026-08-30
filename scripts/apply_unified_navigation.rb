#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
STYLE_URL = "/assets/unified-navigation-v1.css"
SCRIPT_URL = "/assets/unified-navigation-v1.js"
HEAD_START = "<!-- CFMOTO:UNIFIED-NAV:HEAD:START -->"
HEAD_END = "<!-- CFMOTO:UNIFIED-NAV:HEAD:END -->"
HEADER_START = "<!-- CFMOTO:UNIFIED-NAV:HEADER:START -->"
HEADER_END = "<!-- CFMOTO:UNIFIED-NAV:HEADER:END -->"
LANGUAGE_PATTERN = %r{<!-- CFMOTO:LANGUAGE:START -->(.*?)<!-- CFMOTO:LANGUAGE:END -->}m

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  File.write(path, content, encoding: "UTF-8")
end

def language_markup(html, locale)
  existing = html[LANGUAGE_PATTERN, 1]
  return existing.strip if existing

  if locale == "ru"
    '<nav class="language-switcher" aria-label="Выбор языка"><a href="/" lang="az" hreflang="az">AZ</a><span aria-current="page">RU</span></nav>'
  else
    '<nav class="language-switcher" aria-label="Dil seçimi"><span aria-current="page">AZ</span><a href="/ru/" lang="ru" hreflang="ru">RU</a></nav>'
  end
end

def header_markup(locale, language)
  ru = locale == "ru"
  brand_label = ru ? "CFMOTO Азербайджан — главная" : "CFMOTO Azerbaijan ana səhifə"
  brand_country = ru ? "АЗЕРБАЙДЖАН" : "AZƏRBAYCAN"
  topline = ru ? "Официальный представитель CFMOTO в Азербайджане" : "CFMOTO-nun Azərbaycanda rəsmi nümayəndəsi"
  hours = ru ? "пр. Бабека, 188 · Салон ежедневно 10:00–19:00" : "Babək pr. 188 · Salon hər gün 10:00–19:00"
  nav_label = ru ? "Главное меню" : "Əsas menyu"
  models = ru ? "Модели" : "Modellər"
  motorcycles = ru ? "Мотоциклы" : "Motosikletlər"
  atvs = ru ? "Квадроциклы" : "Kvadrosikllər"
  buggy = ru ? "Багги и UTV" : "Buggy və UTV"
  all_models = ru ? "Все модели" : "Bütün modellər"
  accessories = ru ? "Аксессуары" : "Aksesuarlar"
  credit = ru ? "Кредит" : "Kredit"
  service = ru ? "Сервис" : "Servis"
  news = ru ? "Новости" : "Xəbərlər"
  showroom = ru ? "Салон" : "Satış mərkəzi"
  contact = ru ? "Связаться" : "Əlaqə"
  menu_label = ru ? "Открыть меню" : "Menyunu aç"
  moto_path = ru ? "/ru/motocikly/" : "/motosiklet/"
  atv_path = ru ? "/ru/kvadrocikly/" : "/kvadrosikl/"
  buggy_path = ru ? "/ru/buggy/" : "/buggy/"
  credit_path = ru ? "/ru/kredit/" : "/kredit/"
  service_path = ru ? "/ru/servis/" : "/servis/"
  showroom_path = ru ? "/ru/#showroom" : "/#showroom"

  <<~HTML.strip
    #{HEADER_START}
    <div class="unified-topline"><span>#{topline}</span><span class="topline-detail">#{hours}</span></div>
    <header class="site-header unified-site-header">
      <a class="brand" href="#{ru ? '/ru/' : '/'}" aria-label="#{brand_label}"><img src="/cfmoto-logo-black.png" alt="CFMOTO" width="159" height="34"><b>#{brand_country}</b></a>
      <nav class="main-nav" id="site-primary-navigation" aria-label="#{nav_label}">
        <details class="unified-products-menu"><summary>#{models} <span aria-hidden="true">⌄</span></summary><div class="unified-products-panel"><a href="#{moto_path}">#{motorcycles}<span>↗</span></a><a href="#{atv_path}">#{atvs}<span>↗</span></a><a href="#{buggy_path}">#{buggy}<span>↗</span></a><a href="#{ru ? '/ru/#modeller' : '/#modeller'}">#{all_models}<span>↗</span></a></div></details>
        <a href="/aksesuar-konfiquratoru/">#{accessories}</a><a href="#{credit_path}">#{credit}</a><a href="#{service_path}">#{service}</a><a href="/xeberler/">#{news}</a><a href="#{showroom_path}">#{showroom}</a>
        <a class="nav-cta" href="https://wa.me/994512332484?text=Salam%2C%20CFMOTO%20modeli%20haqq%C4%B1nda%20m%C9%99lumat%20almaq%20ist%C9%99yir%C9%99m" target="_blank" rel="noreferrer">#{contact}</a>
      </nav>
      #{language}
      <button class="menu-button" type="button" aria-label="#{menu_label}" aria-expanded="false" aria-controls="site-primary-navigation"><span></span><span></span></button>
    </header>
    #{HEADER_END}
  HTML
end

paths = Dir.glob(File.join(ROOT, "**", "index.html"))
paths << File.join(ROOT, "404.html") if File.file?(File.join(ROOT, "404.html"))
paths.reject! { |path| path.include?("/dist/") }

static_count = 0
paths.uniq.each do |path|
  html = read(path)
  next unless html.include?("</head>") && html.include?("<body")

  html.gsub!(%r{#{Regexp.escape(HEAD_START)}.*?#{Regexp.escape(HEAD_END)}}, "")
  head_block = %(#{HEAD_START}<link rel="stylesheet" href="#{STYLE_URL}"><script defer src="#{SCRIPT_URL}"></script>#{HEAD_END})
  html.sub!("</head>", "#{head_block}</head>")

  relative = path.delete_prefix("#{ROOT}/")
  home_or_model = relative == "index.html" || relative == "ru/index.html" || relative.start_with?("model/", "ru/model/")

  unless home_or_model
    locale = html[/<html[^>]+lang=["']([^"']+)/i, 1].to_s.downcase.start_with?("ru") ? "ru" : "az"
    language = language_markup(html, locale)
    html.gsub!(LANGUAGE_PATTERN, "")
    block = header_markup(locale, language)

    if html.include?(HEADER_START)
      html.sub!(%r{#{Regexp.escape(HEADER_START)}.*?#{Regexp.escape(HEADER_END)}}m, block)
    elsif html.include?('class="news-topline"') && html.include?('class="news-site-nav"')
      html.sub!(%r{<div class="news-topline">.*?</header>}m, block)
    elsif html.include?('class="content-header"')
      html.sub!(%r{(?:<div class="topline">.*?</div>\s*)?<header class="content-header">.*?</header>}m, block)
    elsif html.include?('class="site-header"')
      # Preserve an established interactive site header when one exists.
    else
      html.sub!(%r{<body([^>]*)>}, "<body\\1>#{block}")
    end
    static_count += 1
  end

  write(path, html)
end

puts "Unified navigation applied to #{paths.uniq.size} pages; #{static_count} static headers normalized and mobile category rows kept below the header"

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "domain_config"
require_relative "content_config"
require_relative "category_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
MEASUREMENT_ID = DomainConfig::GA4_MEASUREMENT_ID
GOOGLE_TAG_MANAGER_ID = DomainConfig::GOOGLE_TAG_MANAGER_ID
META_PIXEL_ID = DomainConfig::META_PIXEL_ID
ANALYTICS_START = "<!-- CFMOTO:ANALYTICS:START -->"
ANALYTICS_END = "<!-- CFMOTO:ANALYTICS:END -->"
GTM_HEAD_START = "<!-- CFMOTO:GTM:HEAD:START -->"
GTM_HEAD_END = "<!-- CFMOTO:GTM:HEAD:END -->"
GTM_BODY_START = "<!-- CFMOTO:GTM:BODY:START -->"
GTM_BODY_END = "<!-- CFMOTO:GTM:BODY:END -->"
META_PIXEL_HEAD_START = "<!-- CFMOTO:META-PIXEL:HEAD:START -->"
META_PIXEL_HEAD_END = "<!-- CFMOTO:META-PIXEL:HEAD:END -->"
META_PIXEL_BODY_START = "<!-- CFMOTO:META-PIXEL:BODY:START -->"
META_PIXEL_BODY_END = "<!-- CFMOTO:META-PIXEL:BODY:END -->"
META_PIXEL_GTM_COMMENT = "/* Meta Pixel managed by #{GOOGLE_TAG_MANAGER_ID} */"

abort "Invalid GA4 Measurement ID" unless MEASUREMENT_ID.match?(/\AG-[A-Z0-9]+\z/)
abort "Invalid Google Tag Manager ID" unless GOOGLE_TAG_MANAGER_ID.match?(/\AGTM-[A-Z0-9]+\z/)
abort "Invalid Meta Pixel ID" unless META_PIXEL_ID.match?(/\A\d{10,20}\z/)

gtm_head = <<~HTML
  #{GTM_HEAD_START}
  <script>
  (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
  new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
  j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
  'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
  })(window,document,'script','dataLayer','#{GOOGLE_TAG_MANAGER_ID}');
  </script>
  #{GTM_HEAD_END}
HTML

gtm_body = <<~HTML
  #{GTM_BODY_START}
  <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=#{GOOGLE_TAG_MANAGER_ID}"
  height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
  #{GTM_BODY_END}
HTML

analytics = <<~HTML
  #{ANALYTICS_START}
  <script async fetchpriority="low" src="https://www.googletagmanager.com/gtag/js?id=#{MEASUREMENT_ID}"></script>
  <script>
  window.dataLayer=window.dataLayer||[];
  window.gtag=window.gtag||function(){window.dataLayer.push(arguments)};
  window.gtag('js',new Date());
  window.gtag('config','#{MEASUREMENT_ID}');
  document.addEventListener('click',function(event){
    var target=event.target;
    if(!(target instanceof Element))return;
    var link=target.closest('a[href]');
    if(!link)return;
    var href=link.getAttribute('href')||'';
    var text=(link.textContent||'').trim().replace(/\\s+/g,' ').slice(0,100);
    var normalizedHref=href.toLowerCase();
    var params={link_text:text,page_path:window.location.pathname};
    var send=function(name,extra){window.gtag('event',name,Object.assign({},params,extra||{}))};
    if(normalizedHref.startsWith('https://wa.me/')||normalizedHref.startsWith('https://api.wa.me/')){
      var declaredArea=link.getAttribute('data-contact-area')||(link.closest('[data-contact-area]')||{}).dataset?.contactArea;
      var finance=declaredArea==='finance'||!!link.closest('.calculator,.model-calculator');
      send('whatsapp_click',{contact_area:declaredArea||(finance?'finance':'sales')});
      if(finance)send('finance_lead_click',{lead_type:'whatsapp_offer'});
      return;
    }
    if(normalizedHref.startsWith('tel:')){
      var normalizedText=text.toLowerCase();
      var serviceContact=['servis','ehtiyat','çatdırılma'].some(function(term){return normalizedText.includes(term)});
      send('phone_click',{contact_area:serviceContact?'service':'sales'});
      return;
    }
    if(normalizedHref.includes('maps.app.goo.gl')||normalizedHref.includes('maps.google')||(normalizedHref.includes('google.')&&normalizedHref.includes('/maps'))){
      send('directions_click',{destination:'showroom'});
    }
  },true);
  </script>
  #{ANALYTICS_END}
HTML

def strip_direct_meta_pixel!(content)
  content.gsub!(%r{#{Regexp.escape(META_PIXEL_HEAD_START)}.*?#{Regexp.escape(META_PIXEL_HEAD_END)}\s*}m, "")
  content.gsub!(%r{#{Regexp.escape(META_PIXEL_BODY_START)}.*?#{Regexp.escape(META_PIXEL_BODY_END)}\s*}m, "")

  # The GTM container is the single Meta Pixel owner. The configurator export
  # stores the same inline Pixel source both as HTML and inside Next RSC text;
  # replacing the script body preserves SSR/RSC parity while disabling the
  # duplicate direct initialization.
  pixel_loader = %r{!function\(f,b,e,v,n,t,s\)\{if\(f\.fbq\)return;.*?fbq\('track','PageView'\);}m
  content.gsub!(pixel_loader, META_PIXEL_GTM_COMMENT)
  pixel_noscript = %r{https://www\.facebook\.com/tr\?id=#{Regexp.escape(META_PIXEL_ID)}(?:&amp;|&|\\u0026)ev=PageView(?:&amp;|&|\\u0026)noscript=1}
  content.gsub!(pixel_noscript, "about:blank")
end

news_paths = NewsConfig.html_paths(ROOT)
html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort,
  *ContentConfig.html_paths(ROOT),
  *CategoryConfig.html_paths(ROOT),
  *news_paths
]

html_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  html.gsub!(%r{#{Regexp.escape(ANALYTICS_START)}.*?#{Regexp.escape(ANALYTICS_END)}\s*}m, "")
  html.gsub!(%r{#{Regexp.escape(GTM_HEAD_START)}.*?#{Regexp.escape(GTM_HEAD_END)}\s*}m, "")
  html.gsub!(%r{#{Regexp.escape(GTM_BODY_START)}.*?#{Regexp.escape(GTM_BODY_END)}\s*}m, "")
  strip_direct_meta_pixel!(html)

  abort "#{path}: missing <head> element" unless html.include?("<head>")
  body_match = html.match(%r{<body\b[^>]*>}i)
  abort "#{path}: missing <body> element" unless body_match

  html.sub!("<head>", "<head>#{gtm_head}#{analytics}")
  if news_paths.include?(path)
    body_tag = body_match[0]
    html.sub!(body_tag, "#{body_tag}#{gtm_body}")
  end
  File.write(path, html, encoding: "UTF-8")
end

accessory_path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
abort "Missing accessory configurator page: #{accessory_path}" unless File.file?(accessory_path)

# The standalone configurator ships its own GTM. Keep GTM as the single Meta
# Pixel owner, strip its direct Pixel copy from every HTML/RSC export, and add
# GA4 to the public page.
Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.{html,txt}"), File::FNM_EXTGLOB).each do |path|
  content = File.read(path, encoding: "UTF-8")
  strip_direct_meta_pixel!(content)
  File.write(path, content, encoding: "UTF-8")
end

accessory_html = File.read(accessory_path, encoding: "UTF-8")
accessory_html.gsub!(%r{#{Regexp.escape(ANALYTICS_START)}.*?#{Regexp.escape(ANALYTICS_END)}\s*}m, "")
abort "#{accessory_path}: missing <head> element" unless accessory_html.include?("<head>")
accessory_html.sub!("<head>", "<head>#{analytics}")
File.write(accessory_path, accessory_html, encoding: "UTF-8")

puts "GA4 applied to #{html_paths.size + 1} HTML pages; GTM is the single Meta Pixel source via #{GOOGLE_TAG_MANAGER_ID} (#{MEASUREMENT_ID}, #{META_PIXEL_ID})"

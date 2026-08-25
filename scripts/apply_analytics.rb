#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
MEASUREMENT_ID = DomainConfig::GA4_MEASUREMENT_ID
ANALYTICS_START = "<!-- CFMOTO:ANALYTICS:START -->"
ANALYTICS_END = "<!-- CFMOTO:ANALYTICS:END -->"

abort "Invalid GA4 Measurement ID" unless MEASUREMENT_ID.match?(/\AG-[A-Z0-9]+\z/)

analytics = <<~HTML
  #{ANALYTICS_START}
  <script async src="https://www.googletagmanager.com/gtag/js?id=#{MEASUREMENT_ID}"></script>
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
    var text=(link.textContent||'').trim().replace(/\s+/g,' ').slice(0,100);
    var params={link_text:text,page_path:window.location.pathname};
    var send=function(name,extra){window.gtag('event',name,Object.assign({},params,extra||{}))};
    if(/^https:\/\/(?:api\.)?wa\.me\//i.test(href)){
      var finance=!!link.closest('.calculator,.model-calculator');
      send('whatsapp_click',{contact_area:finance?'finance':'sales'});
      if(finance)send('finance_lead_click',{lead_type:'whatsapp_offer'});
      return;
    }
    if(/^tel:/i.test(href)){
      send('phone_click',{contact_area:/servis|ehtiyat|çatdırılma/i.test(text)?'service':'sales'});
      return;
    }
    if(/(?:maps\.app\.goo\.gl|google\.[^/]+\/maps|maps\.google)/i.test(href)){
      send('directions_click',{destination:'showroom'});
    }
  },true);
  </script>
  #{ANALYTICS_END}
HTML

html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort
]

html_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  html.gsub!(%r{#{Regexp.escape(ANALYTICS_START)}.*?#{Regexp.escape(ANALYTICS_END)}\s*}m, "")
  abort "#{path}: missing <head> element" unless html.include?("<head>")

  html.sub!("<head>", "<head>#{analytics}")
  File.write(path, html, encoding: "UTF-8")
end

puts "GA4 analytics applied to #{html_paths.size} HTML pages (#{MEASUREMENT_ID})"

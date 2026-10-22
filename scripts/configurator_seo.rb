# frozen_string_literal: true

module ConfiguratorSeo
  CANONICAL = "https://cfmoto.az/aksesuar-konfiquratoru/"
  HREFLANGS = {
    "az" => CANONICAL,
    "x-default" => CANONICAL
  }.freeze

  module_function

  def apply_hreflang!(html)
    # The configurator currently has no Russian equivalent. Publish only the
    # Azerbaijani self-reference and x-default instead of pointing crawlers at
    # a non-equivalent /ru/ page.
    html.gsub!(
      %r{<link rel="alternate" hrefLang?="(?:az|az-AZ|x-default)" href="#{Regexp.escape(CANONICAL)}"\s*/?>}i,
      ""
    )
    html.gsub!(
      %r{,\[\\"\$\\",\\"link\\",\\"(?:cfmoto-hreflang-(?:az|x-default)|\d+)\\",\{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"(?:az|az-AZ|x-default)\\",\\"href\\":\\"#{Regexp.escape(CANONICAL)}\\"\}\]},
      ""
    )

    canonical_tag = %(<link rel="canonical" href="#{CANONICAL}"/>)
    abort "Configurator must expose exactly one static canonical" unless html.scan(canonical_tag).size == 1
    static_alternates = HREFLANGS.map do |language, href|
      %(<link rel="alternate" hreflang="#{language}" href="#{href}"/>)
    end.join
    html.sub!(canonical_tag, "#{canonical_tag}#{static_alternates}")

    canonical_rsc_pattern = %r{\[\\"\$\\",\\"link\\",\\"[^\\"]+\\",\{\\"rel\\":\\"canonical\\",\\"href\\":\\"#{Regexp.escape(CANONICAL)}\\"\}\]}
    canonical_rsc = html[canonical_rsc_pattern]
    abort "Configurator RSC canonical metadata not found" unless canonical_rsc
    rsc_alternates = HREFLANGS.map do |language, href|
      key = "cfmoto-hreflang-#{language}"
      %[\[\\"$\\",\\"link\\",\\"#{key}\\",{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"#{language}\\",\\"href\\":\\"#{href}\\"}\]]
    end.join(",")
    html.sub!(canonical_rsc, "#{canonical_rsc},#{rsc_alternates}")

    assert_hreflang!(html)
    html
  end

  def sitemap_entry
    alternates = HREFLANGS.map do |language, href|
      %(<xhtml:link rel="alternate" hreflang="#{language}" href="#{href}"/>)
    end.join
    %(  <url><loc>#{CANONICAL}</loc>#{alternates}</url>\n)
  end

  def assert_hreflang!(html)
    static_pairs = html.scan(
      %r{<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"\s*/?>}i
    )
    expected = HREFLANGS.to_a
    abort "Configurator static hreflang set must be #{expected.inspect}; found #{static_pairs.inspect}" unless static_pairs == expected

    rsc_pairs = html.scan(
      %r{\{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"([^\\"]+)\\",\\"href\\":\\"([^\\"]+)\\"\}}
    )
    abort "Configurator RSC hreflang set must be #{expected.inspect}; found #{rsc_pairs.inspect}" unless rsc_pairs == expected
  end
end

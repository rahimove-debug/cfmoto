# frozen_string_literal: true

module ContentConfig
  SLUGS = %w[
    kredit
    servis
    zemanet
    ehtiyat-hisseleri
    model-muqayisesi
  ].freeze

  LABELS = {
    "kredit" => "Kredit şərtləri",
    "servis" => "Rəsmi servis",
    "zemanet" => "Zəmanət",
    "ehtiyat-hisseleri" => "Ehtiyat hissələri",
    "model-muqayisesi" => "Model müqayisəsi"
  }.freeze

  module_function

  def html_paths(root)
    SLUGS.map { |slug| File.join(root, slug, "index.html") }
  end

  def urls(origin)
    SLUGS.map { |slug| "#{origin}/#{slug}/" }
  end
end

# frozen_string_literal: true

module CategoryConfig
  SLUGS = %w[motosiklet kvadrosikl buggy].freeze

  LABELS = {
    "motosiklet" => "Motosikletlər",
    "kvadrosikl" => "Kvadrosikllər",
    "buggy" => "Buggy və UTV"
  }.freeze

  module_function

  def html_paths(root)
    SLUGS.map { |slug| File.join(root, slug, "index.html") }
  end
end

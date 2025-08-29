# frozen_string_literal: true

Folio::Page.class_eval do
  def self.has_folio_tiptap?
    true
  end

  def tiptap_config
    Folio::Tiptap::Config.new(styled_wrap_variants: [
      {
        variant: "gray-box",
        title: { cs: "Šedý box", en: "Gray box" },
      }
    ])
  end
end

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
        pages_component_class_name: "UnusedDummyClassNameToEnableInTiptap",
        embed_node_class_name: "Dummy::Tiptap::Node::Embed"
      }
    ])
  end
end

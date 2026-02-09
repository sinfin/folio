# frozen_string_literal: true

Folio::Page.class_eval do
  def has_folio_tiptap?
    true
  end

  def tiptap_config(attribute_name: nil)
    Folio::Tiptap::Config.new(embed_node_class_name: "Dummy::Tiptap::Node::Embed",
                              pages_component_class_name: "UnusedDummyClassNameToEnableInTiptap",
                              styled_paragraph_variants: [
                                {
                                  variant: "small",
                                  title: {
                                    cs: "Malý text",
                                    en: "Small text",
                                  },
                                  icon: "arrow-down",
                                },
                                {
                                  variant: "custom-heading",
                                  tag: "h5",
                                  class_name: "custom-heading",
                                  title: {
                                    cs: "Mezititulek",
                                    en: "Custom heading",
                                  },
                                },
                              ],
                              styled_wrap_variants: [{
                                variant: "gray-box",
                                title: { cs: "Šedý box",
                                en: "Gray box" },
                              }])
  end
end

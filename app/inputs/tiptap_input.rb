# frozen_string_literal: true

class TiptapInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = {})
    tiptap_type = options[:block] ? "block" : "rich-text"

    register_stimulus("f-input-tiptap",
                      wrapper: true,
                      values: {
                        loaded: false,
                        origin: ENV["FOLIO_TIPTAP_DEV"] ? "*" : "",
                        type: tiptap_type,
                        render_url: @builder.template.render_nodes_console_api_tiptap_path,
                        tiptap_nodes_json: tiptap_nodes_json(@builder.object.try(:folio_tiptap_nodes) || Folio::Tiptap.default_tiptap_nodes),
                      },
                      action: {
                        "message@window" => "onWindowMessage",
                        "resize@window" => "onWindowResize",
                        "orientationchange@window" => "onWindowResize",
                      })

    input_html_options[:hidden] = true
    input_html_options[:value] = input_html_options[:value] || @builder.object.send(attribute_name) || ""

    if input_html_options[:value].present? && input_html_options[:value].is_a?(Hash)
      input_html_options[:value] = input_html_options[:value].to_json
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    src = if ENV["FOLIO_TIPTAP_DEV"]
      stylesheet_url = if ENV["FOLIO_TIPTAP_DEV"]
        site = Folio::Current.site
        path = site.layout_assets_stylesheets_path
        "#{site.env_aware_root_url}#{@builder.template.stylesheet_path(path)}"
      end

      "http://localhost:5173/?folio-iframe=#{tiptap_type}&folio-iframe-stylesheet-url=#{stylesheet_url}"
    else
      "/folio-tiptap/#{tiptap_type}-editor"
    end

    options[:custom_html] = <<~HTML.html_safe
      <div class="f-input-tiptap__inner">
        <span class="f-input-tiptap__loader folio-loader" data-f-input-tiptap-target="loader"></span>
        <iframe class="f-input-tiptap__iframe" data-f-input-tiptap-target="iframe" src="#{src}"></iframe>
      </div>
    HTML

    @builder.hidden_field(attribute_name, merged_input_options)
  end

  private
    def tiptap_nodes_json(node_names)
      node_names.map do |node_name|
        {
          title: {
            cs: node_name_in_locale(node_name, :cs),
            en: node_name_in_locale(node_name, :en),
          },
          type: node_name,
        }
      end.to_json
    end

    def node_name_in_locale(node_name, locale)
      if I18n.available_locales.include?(locale.to_sym)
        I18n.with_locale(locale) { node_name.constantize.model_name.human }
      else
        I18n.with_locale(I18n.default_locale) { node_name.constantize.model_name.human }
      end
    end
end

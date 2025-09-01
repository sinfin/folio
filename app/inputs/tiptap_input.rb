# frozen_string_literal: true

class TiptapInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = {})
    tiptap_type = options[:block] ? "block" : "rich-text"

    register_stimulus("f-input-tiptap",
                      wrapper: true,
                      values: {
                        loaded: false,
                        ignore_value_changes: true,
                        origin: ENV["FOLIO_TIPTAP_DEV"] ? "*" : "",
                        type: tiptap_type,
                        render_url: @builder.template.render_nodes_console_api_tiptap_path,
                        auto_save_url: @builder.template.console_api_tiptap_revisions_path,
                        placement_type: @builder.object.class.base_class.name,
                        placement_id: @builder.object.id,
                        latest_revision_created_at: latest_revision_created_at,
                        readonly: @builder.template.instance_variable_get(:@audited_audit).present?,
                        tiptap_config_json:,
                        tiptap_content_json_structure_json: Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE.to_json,
                      }.compact,
                      action: {
                        "message@window" => "onWindowMessage",
                        "resize@window" => "onWindowResize",
                        "beforeunload@window" => "onWindowBeforeUnload",
                        "orientationchange@window" => "onWindowResize",
                      })

    input_html_options[:hidden] = true
    input_html_options[:value] = input_html_options[:value] || latest_revision_content || @builder.object.send(attribute_name) || ""

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
    def tiptap_config_json
      (@builder.object.try(:tiptap_config) || Folio::Tiptap.config).to_input_json
    end

    def latest_revision_content
      return nil if @builder.object.new_record?
      return nil unless @builder.object.respond_to?(:latest_tiptap_revision)

      latest_revision = @builder.object.latest_tiptap_revision
      if latest_revision&.content.present?
        value_keys = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE
        { value_keys[:content] => latest_revision.content }
      end
    end
end

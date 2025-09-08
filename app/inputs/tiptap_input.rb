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
                        autosave: tiptap_autosave_enabled?,
                        autosave_url: @builder.template.save_revision_console_api_tiptap_revisions_path,
                        new_record: safe_new_record?,
                        placement_type: safe_placement_type,
                        placement_id: safe_placement_id,
                        latest_revision_at: latest_revision_at,
                        has_unsaved_changes: has_unsaved_changes?,
                        readonly: @builder.template.instance_variable_get(:@audited_audit).present?,
                        tiptap_config_json:,
                        tiptap_content_json_structure_json: Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE.to_json,
                      }.compact,
                      action: {
                        "message@window" => "onWindowMessage",
                        "resize@window" => "onWindowResize",
                        "beforeunload@window" => "onWindowBeforeUnload",
                        "orientationchange@window" => "onWindowResize",
                        "f-c-tiptap-simple-form-wrap:tiptapContinueUnsavedChanges" => "onContinueUnsavedChanges",
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

    def tiptap_autosave_enabled?
      return false if @builder.object.respond_to?(:new_record?) && @builder.object.new_record?

      @builder.object.respond_to?(:tiptap_autosave_enabled?) && @builder.object.tiptap_autosave_enabled?
    end

    def current_user_latest_revision
      @current_user_latest_revision ||= @builder.object.try(:latest_tiptap_revision)
    end

    def has_unsaved_changes?
      return false if safe_new_record?

      current_user_latest_revision.present?
    end

    def latest_revision_content
      return nil unless tiptap_autosave_enabled?

      if current_user_latest_revision&.content.present?
        value_keys = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE
        { value_keys[:content] => current_user_latest_revision.content }
      end
    end

    def latest_revision_at
      return nil unless tiptap_autosave_enabled?

      current_user_latest_revision&.updated_at || safe_updated_at
    end

    private
      def safe_new_record?
        @builder.object.respond_to?(:new_record?) ? @builder.object.new_record? : false
      end

      def safe_placement_type
        if @builder.object.class.respond_to?(:base_class)
          @builder.object.class.base_class.name
        else
          @builder.object.class.name
        end
      end

      def safe_placement_id
        @builder.object.respond_to?(:id) ? @builder.object.id : nil
      end

      def safe_updated_at
        @builder.object.respond_to?(:updated_at) ? @builder.object.updated_at : Time.current
      end
end

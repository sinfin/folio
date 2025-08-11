# frozen_string_literal: true

class Folio::Tiptap::ContentComponent < ApplicationComponent
  CONTROLLER_VARIABLE_NAME = :@folio_tiptap_content_data

  def initialize(record:, attribute: :tiptap_content, class_name: nil)
    @record = record
    @attribute = attribute
    @class_name = class_name
  end

  def render?
    tiptap_content.present? && tiptap_content["content"].present?
  end

  private
    def tiptap_content
      @tiptap_content ||= @record.send(@attribute).presence
    end

    def sanitize_javascript(string)
      Loofah.fragment(string).to_s.tr("'", "`")
    end

    def broken_nodes_javascript_code
      return @broken_nodes_javascript_code if defined?(@broken_nodes_javascript_code)

      @broken_nodes_javascript_code = if controller_instance = try(:controller)
        data = controller_instance.instance_variable_get(CONTROLLER_VARIABLE_NAME)

        if data && data[:broken_nodes].present?
          javascript = ["console.group('[Folio][Tiptap] Broken nodes');"]
          javascript << "console.error('There are #{data[:broken_nodes].length} broken nodes.');"

          data[:broken_nodes].map do |broken_node|
            if broken_node[:prose_mirror_node]
              javascript << "console.group('#{broken_node[:prose_mirror_node]["type"]}');"

              javascript << "console.group('node');"
              javascript << "console.log('#{sanitize_javascript(broken_node[:prose_mirror_node].to_json)}');"
              javascript << "console.groupEnd();"

              if broken_node[:error]
                javascript << "console.group('error');"
                javascript << "console.error('#{sanitize_javascript(broken_node[:error].message)}');"
                javascript << "console.groupEnd();"
              end

              javascript << "console.groupEnd();"
            end
          end

          javascript << "console.groupEnd();"
          javascript.join("\n").html_safe
        end
      end
    end
end

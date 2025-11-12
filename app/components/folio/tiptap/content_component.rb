# frozen_string_literal: true

class Folio::Tiptap::ContentComponent < ApplicationComponent
  CONTROLLER_VARIABLE_NAME = :@folio_tiptap_content_data

  def initialize(record:,
                 attribute: :tiptap_content,
                 class_name: nil,
                 lambda_before_root_node: nil,
                 lambda_after_root_node: nil,
                 node_type_blacklist: nil,
                 lambda_for_blacklisted: nil)
    @record = record
    @attribute = attribute
    @class_name = class_name
    @lambda_before_root_node = lambda_before_root_node
    @lambda_after_root_node = lambda_after_root_node
    @node_type_blacklist = node_type_blacklist
    @lambda_for_blacklisted = lambda_for_blacklisted

    @tiptap_content_information = {
      record: @record,
      attribute: @attribute,
      depth: 0,
      root_node_count: if prose_mirror_node && prose_mirror_node["content"].present?
                         prose_mirror_node["content"].length
                       else
                         0
                       end
    }
  end

  def render?
    prose_mirror_node.present?
  end

  private
    def tiptap_content
      @tiptap_content ||= @record.send(@attribute).presence
    end

    def sanitize_javascript(string)
      Loofah.fragment(string).to_s.tr("'", "`")
    end

    def javascript_code_for_broken_data
      return @javascript_code_for_broken_data if defined?(@javascript_code_for_broken_data)

      @javascript_code_for_broken_data = if controller_instance = try(:controller)
        data = controller_instance.instance_variable_get(CONTROLLER_VARIABLE_NAME)

        if data
          javascript = []

          if data[:broken_nodes].present?
            javascript << "console.group('[Folio][Tiptap] Broken nodes');"
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
          end

          if data[:broken_lambdas].present?
            javascript << "console.group('[Folio][Tiptap] Broken lambdas');"
            javascript << "console.error('There are broken lambdas.');"

            data[:broken_lambdas].map do |key, value|
              javascript << "console.group('#{key}');"

              if value[:error]
                javascript << "console.group('error');"
                javascript << "console.error('#{sanitize_javascript(value[:error].message)}');"
                javascript << "console.groupEnd();"
              end

              javascript << "console.groupEnd();"
            end

            javascript << "console.groupEnd();"
          end

          javascript.join("\n").html_safe
        end
      end
    end

    def prose_mirror_node
      @prose_mirror_node ||= tiptap_content.present? ? tiptap_content[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]] : nil
    end

    def node_component
      Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
        record: @record,
        prose_mirror_node:,
        lambda_before_node: @lambda_before_root_node,
        lambda_after_node: @lambda_after_root_node,
        node_type_blacklist: @node_type_blacklist,
        lambda_for_blacklisted: @lambda_for_blacklisted,
        prose_mirror_node_depth: 0,
        tiptap_content_information: @tiptap_content_information,
      )
    end
end

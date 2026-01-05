# frozen_string_literal: true

class EmbedInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = {})
    register_stimulus("f-input-embed",
                      wrapper: true,
                      action: {
                        "f-input-embed-inner:folio-embed-data-changed" => "onFolioEmbedDataChange"
                      })

    input_html_options[:hidden] = true

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    source_hash = if input_html_options[:value].present?
      if input_html_options[:value].is_a?(Hash)
        input_html_options[:value].stringify_keys
      elsif input_html_options[:value].is_a?(String)
        begin
          JSON.parse(input_html_options[:value])
        rescue JSON::ParserError
          {}
        end
      else
        {}
      end
    else
      if @builder.object.respond_to?(attribute_name)
        @builder.object.send(attribute_name).presence || {}
      else
        {}
      end
    end

    folio_embed_data = if Folio::Embed.invalid_reason_for(source_hash).nil?
      Folio::Embed.normalize_value(source_hash)
    else
      Folio::Embed.normalize_value({ "active" => false })
    end

    options[:custom_html] = @builder.template.capture do
      @builder.template.render(Folio::Input::Embed::InnerComponent.new(folio_embed_data:,
                                                                       centered: !!options[:centered],
                                                                       background_color: options[:background_color],
                                                                       compact: options[:compact]))
    end

    merged_input_options[:value] = if folio_embed_data.present?
      folio_embed_data.to_json
    else
      nil
    end

    @builder.hidden_field(attribute_name, merged_input_options)
  end
end

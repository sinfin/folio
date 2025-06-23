# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::FormComponent < Folio::Console::ApplicationComponent
  def initialize(node:)
    @node = node
  end

  private
    def data
      stimulus_controller("f-c-tiptap-overlay-form")
    end

    def render_input(f:, key:, type:)
      case type
      when :string, :text, :url_json
        send("render_input_#{type}", f: f, key: key)
      else
        raise ArgumentError, "Unsupported input type: #{type}"
      end
    end

    def form(&block)
      opts = {
        url: "#form",
        method: :post,
        as: :tiptap_node_attributes,
        html: {
          class: "f-c-tiptap-overlay-form__form",
          data: stimulus_action(submit: "onFormSubmit")
        },
      }

      helpers.simple_form_for(@node, opts, &block)
    end

    def render_input_string(f:, key:)
      f.input key,
              as: :string,
              character_counter: true
    end

    def render_input_text(f:, key:)
      f.input key,
              as: :text,
              autosize: true,
              character_counter: true
    end

    def render_input_url_json(f:, key:)
      f.input key,
              as: :url_json
    end

    def buttons_model
      [
        {
          variant: :primary,
          type: :submit,
          label: t(".submit"),
        },
        {
          icon: :close,
          variant: :icon,
          data: stimulus_action(click: "onCancelClick"),
        },
      ]
    end
end

# frozen_string_literal: true

class Folio::Console::Tiptap::Overlay::FormComponent < Folio::Console::ApplicationComponent
  def initialize(node:)
    @node = node
  end

  private
    def data
      stimulus_controller("f-c-tiptap-overlay-form",
                          values: {
                            autoclick_cover: should_autoclick_cover?,
                          })
    end

    def should_autoclick_cover?
      @node.class.tiptap_config[:autoclick_cover] == true
    end

    def simple_form_as
      "tiptap_node_attrs[data]"
    end

    def form(&block)
      opts = {
        url: "#form",
        method: :post,
        as: simple_form_as,
        html: {
          class: "f-c-tiptap-overlay-form__form",
          data: stimulus_action(submit: "onFormSubmit")
        },
      }

      helpers.simple_form_for(@node, opts, &block)
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

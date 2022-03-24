# frozen_string_literal: true

class Folio::Console::ReactAncestryCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def items
    model.arrange_serializable(order: :position) do |parent, children|
      {
        id: parent.id,
        to_label: parent.to_label,
        url: url_for([:edit, :console, parent]),
        destroy_url: parent.class.try(:indestructible?) ? nil : url_for([:console, parent]),
        valid: parent.valid?,
        children:,
      }
    end
  end

  def max_nesting_depth
    options[:max_nesting_depth] || 2
  end

  def form(&block)
    opts = {
      url: url_for([:ancestry, :console, model]),
      html: { class: "f-c-react-ancestry f-c-dirty-simple-form" },
      method: :post,
    }

    simple_form_for("", opts, &block)
  end
end

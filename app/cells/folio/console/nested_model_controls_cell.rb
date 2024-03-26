# frozen_string_literal: true

class Folio::Console::NestedModelControlsCell < Folio::ConsoleCell
  include Cocoon::ViewHelpers

  class_name "f-c-nested-model-controls", :vertical, :no_margin?

  def f
    model
  end

  def handle_position?
    return false unless model.object.respond_to?(:position)
    options[:only].blank? || options[:only] == :position
  end

  def handle_destroy?
    options[:only].blank? || options[:only] == :destroy
  end

  def destroy_label
    unless options[:vertical]
      t(".destroy")
    end
  end

  def buttons_model
    ary = []

    if handle_position?
      %w[up down].each do |direction|
        ary << {
          icon: "arrow_#{direction}".to_sym,
          class: "f-c-nested-model-controls__position-button",
          variant: :secondary,
          "data-direction" => direction,
        }
      end
    end

    if handle_destroy?
      ary << {
        icon: :delete,
        class: "f-c-nested-model-controls__destroy-button",
        variant: :danger,
        label: destroy_label,
      }
    end

    ary
  end

  def no_margin?
    options[:no_margin] || options[:vertical]
  end
end

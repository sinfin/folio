# frozen_string_literal: true

class Folio::Addresses::FieldsCell < Folio::ApplicationCell
  include ActionView::Helpers::FormOptionsHelper

  def show
    %i[primary_address secondary_address].each do |key|
      model.object.send("build_#{key}") if model.object.send(key).nil?
    end

    render
  end

  def title_tag
    { tag: options[:title_tag] || "h2", class: "mt-0" }
  end
end

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

  def required?(all_blank)
    options[:mark_as_required] || !all_blank
  end

  def data_country_code(key)
    model.object.send(key).try(:country_code) || begin
      if key == :primary_address
        Folio::Address::Primary.priority_countries(locale: I18n.locale).first
      elsif key == :secondary_address
        Folio::Address::Secondary.priority_countries(locale: I18n.locale).first
      else
        Folio::Address::Base.priority_countries(locale: I18n.locale).first
      end
    end
  end

  def country_code_input(g)
    g.input :country_code,
            priority: g.object.class.priority_countries(locale: I18n.locale),
            input_html: { class: "f-addresses-fields__country-code-input" }
  end

  def address_line_input(g, key, required: false)
    g.input key,
            required:,
            label: "<span class=\"f-addresses-fields__address-line-label f-addresses-fields__address-line-label--regular\">#{t(".#{key}_regular")}</span> \
                    <span class=\"f-addresses-fields__address-line-label f-addresses-fields__address-line-label--inline\">#{t(".#{key}_inline")}</span>".html_safe
  end
end

# frozen_string_literal: true

class Folio::Addresses::FieldsCell < Folio::ApplicationCell
  include ActionView::Helpers::FormOptionsHelper

  def show
    %i[primary_address secondary_address].each do |key|
      model.object.send("build_#{key}") if send("show_#{key}_fields?") && model.object.send(key).nil?
    end

    render
  end

  %i[primary_address secondary_address].each do |key|
    define_method("show_#{key}_fields?") do
      options[key] != false
    end
  end

  def title_tag
    { tag: options[:title_tag] || "h2", class: "mt-0" }
  end

  def required?(key, attributes)
    return true if model.object.send("should_validate_#{key}?")
    all_blank = attributes.all? { |attr, val| attr == "type" || val.blank? }
    !all_blank
  end

  def data_country_code(key)
    model.object.send(key).try(:country_code) || begin
      address_class = case key
                      when :primary_address
                        Folio::Address::Primary
                      when :secondary_address
                        Folio::Address::Secondary
                      else
                        Folio::Address::Base
      end

      address_class.priority_countries(locale: I18n.locale).first || address_class.countries_whitelist.try(:first)
    end
  end

  def country_code_input(g, disabled: false)
    g.input :country_code,
            disabled:,
            only: g.object.class.countries_whitelist,
            priority: g.object.class.priority_countries(locale: I18n.locale),
            input_html: { class: "f-addresses-fields__country-code-input", id: nil },
            include_blank: false
  end

  def address_line_input(g, key, disabled: false, required: false)
    g.input key,
            disabled:,
            required:,
            input_html: { id: nil },
            label: "<span class=\"f-addresses-fields__address-line-label f-addresses-fields__address-line-label--regular\">#{t(".#{key}_regular")}</span> \
                    <span class=\"f-addresses-fields__address-line-label f-addresses-fields__address-line-label--inline\">#{t(".#{key}_inline")}</span>".html_safe
  end
end

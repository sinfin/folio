# frozen_string_literal: true

class Folio::Console::PublishableInputs::ItemCell < Folio::ConsoleCell
  class_name "f-c-publishable-inputs-item", :date?, :active?, :date_restricted?

  def f
    model[:f]
  end

  def field
    model[:field]
  end

  def read_only?
    if @read_only.nil?
      input_to_event = {
        published: :publish,
        featured: :feature
      }

      @read_only = if Folio::Current.user.blank?
        false
      elsif !input_to_event.key?(field.to_sym)
        false
      else
        !can_now?(input_to_event[field.to_sym], f.object, site: Folio::Current.site)
      end
    end
    @read_only
  end

  def date_at?
    return @date_at unless @date_at.nil?
    @date_at = f.object.respond_to?("#{field}_at")
  end

  def date_between?
    return @date_between unless @date_between.nil?
    @date_between = f.object.respond_to?("#{field}_from") && f.object.respond_to?("#{field}_until")
  end

  def date?
    date_at? || date_between?
  end

  def active?
    !date_restricted? && !!f.object.send(field)
  end

  def date_restricted?
    return unless field == :published

    record = f.object
    now = Time.zone.now

    if date_at? && record.published_at.present?
      now < record.published_at
    elsif date_between? && record.published_from.present? && record.published_until.present?
      now < record.published_from || now > record.published_until
    end
  end

  def input_html(class_name_element = nil, placeholder: nil, checkbox: false)
    b = { class: class_name_element ? "f-c-publishable-inputs-item__#{class_name_element}" : nil }

    b[:id] = nil if options[:no_input_ids]
    b[:name] = nil if options[:no_input_names]
    b[:placeholder] = placeholder

    if checkbox
      b["data-action"] = "change->f-c-publishable-inputs-item#onCheckboxChange folioCustomChange->f-c-publishable-inputs-item#onCheckboxChange"
    end

    b
  end

  def data
    {
      controller: "f-c-publishable-inputs-item"
    }
  end

  def wrapper_html
    { class: "f-c-publishable-inputs-item__wrapper" }
  end
end

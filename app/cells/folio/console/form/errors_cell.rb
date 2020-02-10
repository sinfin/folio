# frozen_string_literal: true

class Folio::Console::Form::ErrorsCell < Folio::ConsoleCell
  def show
    render if errors.present?
  end

  def full_messages
    @full_messages ||= errors.full_messages
  end

  def errors
    options[:errors] || model.object.errors
  end

  def field_name(key)
    key
    # *parts, final = key.to_s.split('.')
    # [
    #   model.object_name,
    #   *parts.map { |part| "[#{part}_attributes]" },
    #   "[#{final}]",
    # ].join('')
  end
end

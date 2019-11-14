# frozen_string_literal: true

class Folio::Console::Form::ErrorsCell < Folio::ConsoleCell
  def show
    render if model.object.errors.present?
  end

  def full_messages
    @full_messages ||= model.object.errors.full_messages
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

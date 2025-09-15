# frozen_string_literal: true

ActiveModel::Validations::Comparability.module_eval do
  def error_options(value, option_value)
    options.except(*ActiveModel::Validations::Comparability::COMPARE_CHECKS.keys).merge!(
      count: localize_value(option_value),
      value: localize_value(value)
    )
  end

  def localize_value(value)
    return value unless value.respond_to?(:strftime)

    I18n.l(value, format: :folio_short)
  end
end

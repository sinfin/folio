# frozen_string_literal: true

class Folio::Console::TranslatedInputsCell < FolioCell
  def f
    model[:f]
  end

  def key
    model[:key]
  end

  def args
    model[:args]
  end

  def translations
    @translations ||= begin
      if f.object.class.column_names.include?(key.to_s)
        nil
      else
        f.object.class
                .column_names
                .grep(/\A#{key}_\w+/)
                .map { |t| t.gsub(/\A#{key}_/, '') }
      end
    end
  end

  def args_with_locale(locale)
    common = { wrapper: :with_flag, flag: locale }

    if args.present? && args.first.present?
      [
        args.first.merge(common)
      ] + args[1..-1]
    else
      [common]
    end
  end
end

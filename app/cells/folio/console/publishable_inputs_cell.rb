# frozen_string_literal: true

class Folio::Console::PublishableInputsCell < Folio::ConsoleCell
  def show
    render if fields.present?
  end

  def f
    model
  end

  def publishable_with_date?
    f.object.respond_to?(:published_at)
  end

  def publishable_within?
    f.object.respond_to?(:published_from) && f.object.respond_to?(:published_until)
  end

  def featurable_within?
    f.object.respond_to?(:featured_from) && f.object.respond_to?(:featured_until)
  end

  def fields
    @fields ||= begin
      ary = %i[published featured]

      ary += options[:additional_fields] if options[:additional_fields]

      ary.filter do |field|
        f.object.respond_to?(field)
      end
    end
  end
end

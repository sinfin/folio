# frozen_string_literal: true

class Folio::Devise::Omniauth::IconCell < Folio::ApplicationCell
  def size_class_name
    if options[:size]
      "f-devise-omniauth-icon--size-#{options[:size]}"
    end
  end

  def color_class_name
    if options[:color]
      "f-devise-omniauth-icon--color"
    end
  end
end

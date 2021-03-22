# frozen_string_literal: true

class Dummy::Ui::IconCell < ApplicationCell
  def size_class_name
    if options[:size]
      "d-ui-icon--#{options[:size]}"
    end
  end
end

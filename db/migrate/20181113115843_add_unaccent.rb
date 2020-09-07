# frozen_string_literal: true

class AddUnaccent < ActiveRecord::Migration[5.2]
  def change
    enable_extension "unaccent"
  end
end

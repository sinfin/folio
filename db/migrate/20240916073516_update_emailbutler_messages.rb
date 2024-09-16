# frozen_string_literal: true

class UpdateEmailbutlerMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :emailbutler_messages, :site
    add_column :emailbutler_messages, :subject, :string
  end
end

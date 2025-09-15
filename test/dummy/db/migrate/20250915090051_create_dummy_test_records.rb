# frozen_string_literal: true

class CreateDummyTestRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :dummy_test_records do |t|
      t.string :title

      t.boolean :published
      t.datetime :published_at
      t.datetime :published_from
      t.datetime :published_until

      t.timestamps
    end
  end
end

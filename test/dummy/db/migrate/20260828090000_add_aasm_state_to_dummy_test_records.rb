# frozen_string_literal: true

class AddAasmStateToDummyTestRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :dummy_test_records, :aasm_state, :string
    add_column :dummy_test_records, :email, :string
  end
end

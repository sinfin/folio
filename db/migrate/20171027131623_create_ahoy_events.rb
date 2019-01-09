class CreateAhoyEvents < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:ahoy_events)
      create_table :ahoy_events do |t|
        t.integer :visit_id

        # user
        t.belongs_to :account
        # add t.string :user_type if polymorphic

        t.string :name
        t.jsonb :properties
        t.timestamp :time
      end

      add_index :ahoy_events, [:visit_id, :name]
      add_index :ahoy_events, [:name, :time]
    end
  end
end

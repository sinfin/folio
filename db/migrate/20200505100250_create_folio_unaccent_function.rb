# frozen_string_literal: true

class CreateFolioUnaccentFunction < ActiveRecord::Migration[5.2]
  def up
    say_with_time 'create folio_unaccent function' do
      create_folio_unaccent
    end
  end

  def down
    say_with_time 'drop folio_unaccent function' do
      drop_folio_unaccent
    end
  end
end

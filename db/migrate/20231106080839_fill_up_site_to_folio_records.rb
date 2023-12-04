# frozen_string_literal: true

class FillUpSiteToFolioRecords < ActiveRecord::Migration[7.0]
  def up
    # it is in migration, because it must done right after deploy
    correct_name = Rake::Task.tasks.collect(&:name).detect { |tn| tn.include?("idp_fill_up_site_to_folio_records") }
    Rake::Task[correct_name].invoke()
  end

  def down
  end
end

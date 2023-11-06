# frozen_string_literal: true

class FillUpSiteToFolioRecords < ActiveRecord::Migration[7.0]
  def up
    # it is in migration, beacouse it must done right after deploy
    Rake::Task["app:developer_tools:idp_fill_up_site_to_folio_records"].invoke()
  end

  def down
  end
end

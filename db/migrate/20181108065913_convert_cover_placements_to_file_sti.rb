class ConvertCoverPlacementsToFileSti < ActiveRecord::Migration[5.2]
  def change
    conn = ActiveRecord::Base.connection

    %w(Image Document).each do |key|
      raw_ids = conn.execute <<~SQL
        SELECT folio_file_placements.id
        FROM folio_file_placements
        INNER JOIN folio_files
          ON folio_file_placements.file_id = folio_files.id
        WHERE
          folio_files.type = 'Folio::#{key}'
      SQL
      ids = raw_ids.pluck('id').join(',')

      if ids != ''
        conn.execute <<~SQL
          UPDATE folio_file_placements
          SET
            type = 'Folio::FilePlacement::#{key}'
          WHERE
            id IN (#{ids})
        SQL
      end
    end

    cover_placements = conn.exec_query('SELECT * FROM folio_cover_placements')
                           .to_hash

    cover_placements.each do |cover_placement|
      conn.execute <<~SQL
        INSERT INTO folio_file_placements (type,
                                           placement_type,
                                           placement_id,
                                           file_id,
                                           created_at,
                                           updated_at)
        VALUES ('Folio::FilePlacement::Cover',
                '#{cover_placement['placement_type']}',
                '#{cover_placement['placement_id']}',
                '#{cover_placement['file_id']}',
                '#{cover_placement['created_at']}',
                '#{cover_placement['updated_at']}')
      SQL
    end

    drop_table :folio_cover_placements

    remove_column :folio_file_placements, :caption

    add_column :folio_file_placements, :title, :text
    add_column :folio_file_placements, :alt, :string
  end
end

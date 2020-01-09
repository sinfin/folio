# frozen_string_literal: true

require 'tempfile'
require 'zip'

module Folio::Console::FileControllerBase
  extend ActiveSupport::Concern

  def index
  end

  def mass_download
    ids = params.require(:ids).split(',')
    files = @klass.where(id: ids)

    tmp_zip_file = Tempfile.new('folio-files')

    Zip::File.open(tmp_zip_file.path, Zip::File::CREATE) do |zip|
      files.each do |file|
        # dragonfly ¯\_(ツ)_/¯
        tmp_file = file.file.file
        zip.add("#{file.id}-#{file.file_name}", tmp_file)
      end
    end

    zip_data = File.read(tmp_zip_file.path)
    send_data(zip_data, type: 'application/zip',
                        filename: "#{@klass.model_name.human(count: 2)}-#{Time.zone.now.to_i}.zip")
  end

  private

    def file_params
      p = params.require(:file)
                .permit(:tag_list,
                        :type,
                        :file,
                        tags: [])

      if p[:tags].present? && p[:tag_list].blank?
        p[:tag_list] = p.delete(:tags).join(',')
      end

      p
    end
end

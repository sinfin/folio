# frozen_string_literal: true

class Folio::FileListComponent < Folio::ApplicationComponent
  def initialize(file_klass:,
                 files: nil,
                 files_pagy: nil,
                 upload: true)
    @file_klass = file_klass
    @files = files
    @files_pagy = files_pagy
    @upload = upload
  end

  def data
    stimulus_controller("f-file-list",
                        values: {
                          file_type: @file_klass.to_s,
                        },
                        action: {
                          "f-uppy:upload-success": "uppyUploadSuccess",
                        })
  end
end

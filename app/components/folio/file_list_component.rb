# frozen_string_literal: true

class Folio::FileListComponent < Folio::ApplicationComponent
  def initialize(file_klass:,
                 files: nil,
                 upload: true,
                 editable: true,
                 destroyable: false,
                 primary_action: nil)
    @file_klass = file_klass
    @files = files
    @upload = upload
    @editable = editable
    @destroyable = destroyable
    @primary_action = primary_action
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

  def file_args(file: nil, template: false)
    @file_args ||= {
      file: nil,
      template: false,
      file_klass: @file_klass,
      editable: @editable,
      destroyable: @destroyable,
      primary_action: @primary_action,
    }

    @file_args.merge(file:, template:)
  end
end

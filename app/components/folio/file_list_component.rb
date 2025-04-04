# frozen_string_literal: true

class Folio::FileListComponent < Folio::ApplicationComponent
  def initialize(file_klass:,
                 files: nil,
                 upload: true,
                 editable: true,
                 destroyable: false,
                 selectable: false,
                 primary_action: nil)
    @file_klass = file_klass
    @files = files
    @upload = upload
    @editable = editable
    @destroyable = destroyable
    @selectable = selectable
    @primary_action = primary_action
  end

  def data
    stimulus_controller("f-file-list",
                        values: {
                          file_type: @file_klass.to_s,
                        },
                        action: {
                          "f-uppy:upload-success": "uppyUploadSuccess",
                          "f-c-files-display-toggle:table-view-change": "tableViewChange"
                        })
  end

  def file_args(file: nil, template: false)
    @file_args ||= {
      file: nil,
      template: false,
      file_klass: @file_klass,
      editable: @editable,
      destroyable: @destroyable,
      selectable: @selectable,
      primary_action: @primary_action,
    }

    @file_args.merge(file:, template:)
  end

  def view_class_names
    if @file_klass.try(:human_type) == "image"
      if Folio::Current.user && Folio::Current.user.console_preferences.present? && Folio::Current.user.console_preferences["images_table_view"]
        "f-file-list--view-changeable f-file-list--view-table"
      else
        "f-file-list--view-changeable f-file-list--view-grid"
      end
    else
      "f-file-list--view-table"
    end
  end
end

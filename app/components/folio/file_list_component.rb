# frozen_string_literal: true

class Folio::FileListComponent < Folio::ApplicationComponent
  def initialize(file_klass:,
                 files: nil,
                 uploadable: false,
                 editable: true,
                 destroyable: false,
                 selectable: false,
                 removable_from_batch: nil,
                 batch_actions: false,
                 primary_action: nil,
                 allow_thumbnail_view: true,
                 thead: true,
                 reload_pagy: false)
    @file_klass = file_klass
    @files = files
    @uploadable = uploadable
    @editable = editable
    @destroyable = destroyable
    @removable_from_batch = removable_from_batch.nil? ? batch_actions : removable_from_batch
    @selectable = selectable
    @batch_actions = batch_actions
    @primary_action = primary_action
    @allow_thumbnail_view = allow_thumbnail_view
    @thead = thead
    @reload_pagy = reload_pagy
  end

  def data
    stimulus_controller("f-file-list",
                        values: {
                          file_type: @file_klass.to_s,
                          reload_pagy: @reload_pagy,
                        },
                        action: {
                          "f-uppy:upload-success": "uppyUploadSuccess",
                          "f-c-files-display-toggle:table-view-change": "tableViewChange",
                        })
  end

  def file_args(file: nil, template: false, thead: false)
    @file_args ||= {
      file: nil,
      template: false,
      thead: false,
      file_klass: @file_klass,
      editable: @editable,
      destroyable: @destroyable,
      selectable: @selectable,
      batch_actions: @batch_actions || @removable_from_batch,
      primary_action: @primary_action,
    }

    @file_args.merge(file:, template:, thead:)
  end

  def view_class_names
    if @allow_thumbnail_view && @file_klass.try(:human_type) == "image"
      if Folio::Current.user && Folio::Current.user.console_preferences.present? && Folio::Current.user.console_preferences["images_table_view"]
        "f-file-list--view-changeable f-file-list--view-table"
      else
        "f-file-list--view-changeable f-file-list--view-grid"
      end
    else
      "f-file-list--view-table"
    end
  end

  def blank_message
    blank_prompt = content_tag(:span,
                               t(".blank_prompt"),
                               data: stimulus_click_trigger(".f-file-list-trigger"),
                               class: "f-file-list__blank-trigger")
    t(".blank", blank_prompt:).html_safe
  end

  def new_file
    @new_file ||= @file_klass.new
  end
end

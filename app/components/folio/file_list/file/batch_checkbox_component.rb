# frozen_string_literal: true

class Folio::FileList::File::BatchCheckboxComponent < Folio::ApplicationComponent
  def initialize(file:, file_klass: nil, thead: false)
    @file = file
    @file_klass = file_klass || file.class
    @thead = thead
  end

  def data
    stimulus_controller("f-file-list-file-batch-checkbox",
                        action: {
                          "f-c-files-batch-bar:batchUpdated" => "batchUpdated",
                        })
  end

  def input_data
    stimulus_data(target: "input",
                  action: {
                    "input" => @thead ? "onGlobalBatchActionCheckboxInput" : "onBatchActionCheckboxInput",
                    "f-c-files-batch-bar:batchUpdated" => "batchUpdated",
                  })
  end

  def selected_for_batch_actions?
    return false if @file.try(:id).blank?

    batch_service.has_file?(@file.id)
  end

  private
    def batch_service
      @batch_service ||= Folio::Console::Files::BatchService.new(
        session_id: controller.session.id.public_id,
        file_class_name: @file_klass.to_s
      )
    end
end

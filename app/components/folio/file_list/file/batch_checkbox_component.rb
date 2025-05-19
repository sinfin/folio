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

    file_ids = controller.session.dig(Folio::Console::Api::FileControllerBase::BATCH_SESSION_KEY, @file_klass.to_s, "file_ids")
    return false if file_ids.blank?

    file_ids.include?(@file.id)
  end
end

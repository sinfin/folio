# frozen_string_literal: true

class Folio::UppyComponent < Folio::ApplicationComponent
  bem_class_name :inline, :custom_trigger

  def initialize(file_type: "Folio::File::Image",
                 inline: false,
                 max_number_of_files: nil,
                 existing_id: nil,
                 max_file_size: 5 * 1024 * 1024 * 1024)
    @file_type = file_type
    @inline = inline
    @max_number_of_files = max_number_of_files
    @existing_id = existing_id
    @max_file_size = max_file_size
  end

  def data
    stimulus_controller("f-uppy",
                        values: {
                          file_type: @file_type,
                          inline: @inline,
                          max_number_of_files: @max_number_of_files || 0,
                          existing_id: @existing_id,
                          allowed_formats: allowed_formats&.join(","),
                          max_file_size: @max_file_size
                        })
  end

  private
    def allowed_formats
      file_type_class = @file_type.constantize
      return nil unless file_type_class.respond_to?(:valid_mime_types)

      file_type_class.valid_mime_types
    rescue NameError
      nil
    end
end

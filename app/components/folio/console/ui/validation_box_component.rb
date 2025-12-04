# frozen_string_literal: true

class Folio::Console::Ui::ValidationBoxComponent < Folio::Console::ApplicationComponent
  def initialize(errors: nil,
                 warnings: nil,
                 record:,
                 class_name: nil)
    @errors = errors
    @warnings = errors.present? ? nil : warnings
    @variant = @errors.present? ? :danger : :warning
    @record = record
    @class_name = class_name
  end

  def render?
    @errors.present? || @warnings.present?
  end

  private
    def data
      stimulus_controller("f-c-ui-validation-box")
    end

    # Danger variant methods

    def dig_error_message(error)
      if ie = error.try(:inner_error)
        dig_error_message(ie)
      else
        error.full_message
      end
    end

    def button_data(error)
      {
        "error-field" => error.attribute,
        "error-type" => (error.options && error.options[:message]) || error.type,
        "f-c-ui-validation-box-target" => "button",
        "action" => "f-c-ui-validation-box#onButtonClick"
      }
    end

    def show_fix_button?(error)
      return true if button_blacklist.blank?

      button_blacklist.exclude?(error.attribute.to_s)
    end

    def button_blacklist
      @button_blacklist ||= if @record.respond_to?(:folio_console_ui_validation_box_button_blacklist)
        Array(@record.folio_console_ui_validation_box_button_blacklist).map(&:to_s)
      end
    end

    # Warning variant methods

    def can_read_file?(file)
      return false if file.blank?
      can_now?(:read, file)
    end

    def file_url(file)
      return nil if file.blank?
      url_for([:console, file])
    end

    def file_label(file)
      return nil if file.blank?
      file.file_name
    end

    def warnings_text(warnings)
      translated = warnings.map { |key| t(".#{key}") }

      # Try to combine warnings with common prefix
      # e.g., "nemá vyplněný A, nemá vyplněný B" -> "nemá vyplněný A a B"
      combined = combine_warnings_with_common_prefix(translated)
      combined || translated.join(", ")
    end

    def combine_warnings_with_common_prefix(warnings)
      return nil if warnings.empty? || warnings.length < 2

      # Map prefix groups to their base prefix and connector
      # Group similar prefixes together (e.g., "nemá vyplněný" and "nemá vyplněného")
      prefix_groups = {
        ["nemá vyplněný ", "nemá vyplněného "] => { base: "nemá vyplněný ", connector: " a " },
        ["is missing "] => { base: "is missing ", connector: " and " }
      }

      # Find which prefix group matches
      matching_group = prefix_groups.find do |prefixes, _config|
        warnings.all? { |w| prefixes.any? { |prefix| w.start_with?(prefix) } }
      end

      return nil if matching_group.blank?

      config = matching_group[1]
      base_prefix = config[:base]
      connector = config[:connector]

      # Extract the parts after their respective prefixes
      parts = warnings.map do |w|
        matching_prefix = matching_group[0].find { |prefix| w.start_with?(prefix) }
        w.delete_prefix(matching_prefix).strip
      end

      # Combine: "prefix part1, part2 a part3"
      if parts.length == 2
        "#{base_prefix}#{parts[0]}#{connector}#{parts[1]}"
      else
        "#{base_prefix}#{parts[0..-2].join(", ")}#{connector}#{parts.last}"
      end
    end

    def file_button_data(file)
      stimulus_action(click: "openFileShowModal").merge("file-data": {
        type: file.class.name,
        id: file.id,
        fileName: file.file_name,
      }.to_json)
    end
end

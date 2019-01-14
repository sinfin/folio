# frozen_string_literal: true

module Folio
  module Console::StiHelper
    def sti_records_for_select(records, show_model_names: true, add_content: false)
      records.map do |record|
        record_name = record.try(:to_console_label) ||
                      record.try(:to_label) ||
                      record.try(:title) ||
                      record.model_name.human

        label = [
          show_model_names ? record.model_name.human : nil,
          record_name,
        ].compact.join(' / ')

        value = [
          record.try(:type) || record.class.to_s,
          record.id
        ].join(Console::BaseController::TYPE_ID_DELIMITER)

        [
          label,
          value,
          add_content ? { 'data-content' => record.try(:to_content) } : nil,
        ].compact
      end.sort_by(&:first)
    end

    def sti_record_select_value(record, relation_name)
      related_model = record.send(relation_name)
      return nil if related_model.blank?

      [
        related_model.class.to_s,
        related_model.id,
      ].join(Console::BaseController::TYPE_ID_DELIMITER)
    end
  end
end

# frozen_string_literal: true

module Folio
  module Console::StiHelper
    def sti_records_for_select(records, show_model_names: true, add_content: false)
      records.map do |record|
        record_name = record.try(:to_label) ||
                      record.try(:title) ||
                      record.model_name.human

        label = [
          show_model_names ? record.model_name.human : nil,
          record_name,
        ].compact.join(' / ')

        value = [
          record.type,
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
      return nil if record.send(relation_name).blank?

      relation_type = "#{relation_name}_type".to_sym
      relation_id = "#{relation_name}_id".to_sym

      [
        record.send(relation_type),
        record.send(relation_id)
      ].join(Console::BaseController::TYPE_ID_DELIMITER)
    end
  end
end

# frozen_string_literal: true

class Folio::Console::Audited::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(audits:, audit: nil, record:)
    @audits = audits
    @audit = audit
    @record = record
  end

  def render?
    @audits.present? && @audits.size > 1 && @record && @record.should_audit_changes?
  end

  def item_class_name(version, i)
    if @audit
      active = @audit.present? && version.id == @audit.id
    else
      active = i == 0
    end

    if active
      "f-c-audited-dropdown__item--active"
    else
      "f-c-audited-dropdown__item--link"
    end
  end

  def version_url(version, i)
    if i == 0
      url_for([:edit, :console, @record])
    else
      url_for([:revision, :console, @record, version: version.version])
    end
  end

  def pretty_print_changes(version)
    return t(".created") if version.action == "create"

    audited_changes = version.audited_changes
    ary = []

    if audited_changes["aasm_state"]
      ary << "#{@record.class.human_attribute_name(:aasm_state)}: #{audited_changes["aasm_state"][0]} > #{audited_changes["aasm_state"][1]}"
    end

    second_line = []

    if audited_changes["folio_audited_changed_relations"].present?
      first = audited_changes["folio_audited_changed_relations"][1]

      if first.is_a?(String)
        second_line << @record.class.human_attribute_name(first)
      elsif first.is_a?(Array)
        second_line += first.map do |key|
          @record.class.human_attribute_name(key)
        end
      end
    end

    second_line += audited_changes.without("aasm_state", "folio_audited_changed_relations").map do |key, value|
      @record.class.human_attribute_name(key)
    end

    if second_line.present?
      ary << second_line.join(", ")
    end

    ary.join("<br>").html_safe
  end
end

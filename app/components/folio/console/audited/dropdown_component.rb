# frozen_string_literal: true

class Folio::Console::Audited::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(audits:, audit: nil, record:)
    @audits = audits
    @audit = audit
    @record = record
  end

  def render?
    @audits.present? && @record && @record.should_audit_changes?
  end

  def dropdown_item_tag(version, i)
    tag = { tag: :div, class: "dropdown-item f-c-audited-dropdown__item" }

    active = if @audit
      @audit.present? && version.id == @audit.id
    else
      i == 0
    end

    if active
      tag[:class] += " f-c-audited-dropdown__item--active"
    else
      tag[:class] += " f-c-audited-dropdown__item--link"
      tag[:tag] = :a
      tag[:href] = version_url(version, i)
    end

    tag
  end

  def version_url(version, i)
    if i == 0
      url_for([:edit, :console, @record])
    else
      url_for([:revision, :console, @record, version: version.version])
    end
  end

  def pretty_print_state(state)
    state_instance = @record.aasm.states.find { |s| s.name.to_s == state.to_s }

    if state_instance
      state_instance.human_name
    else
      state.to_s
    end
  end

  def pretty_print_changes(version)
    return t(".created") if version.action == "create"

    audited_changes = version.audited_changes
    ary = []

    if audited_changes["aasm_state"] && audited_changes["aasm_state"].size > 1
      from = audited_changes["aasm_state"][0]
      to = audited_changes["aasm_state"][1]

      ary << "#{@record.class.human_attribute_name(:aasm_state)}: #{pretty_print_state(from)} > #{pretty_print_state(to)}"
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

# frozen_string_literal: true

class Folio::Ai::FormContext
  attr_reader :integration_key,
              :endpoint,
              :record,
              :site,
              :user,
              :current_state_policy

  def initialize(integration_key:,
                 endpoint:,
                 record: nil,
                 site: Folio::Current.site,
                 user: Folio::Current.user,
                 current_state_policy: :persisted_record,
                 host_eligible: true,
                 disabled: false)
    @integration_key = integration_key.to_s
    @endpoint = endpoint
    @record = record
    @site = site
    @user = user
    @current_state_policy = current_state_policy.to_sym
    @host_eligible = host_eligible
    @disabled = disabled
  end

  def disabled?
    @disabled
  end

  def record_ready?
    return false if disabled?

    case current_state_policy
    when :persisted_record
      record.respond_to?(:persisted?) ? record.persisted? : record.present?
    when :current_form_snapshot
      record.present?
    else
      false
    end
  end

  def availability_for(field_key:, attribute_name: field_key)
    Folio::Ai::Availability.new(site:,
                                integration_key:,
                                field_key:,
                                host_eligible: host_eligible_for(field_key:, attribute_name:)).call
  end

  def user_instruction_for(field_key:)
    return "" if user.blank? || site.blank?

    Folio::Ai::UserInstruction.find_or_initialize_for(user:,
                                                      site:,
                                                      integration_key:,
                                                      field_key:).instruction.to_s
  end

  private
    def host_eligible_for(field_key:, attribute_name:)
      return host_eligible unless host_eligible.respond_to?(:call)

      host_eligible.call(field_key:, attribute_name:, record:)
    end

    attr_reader :host_eligible
end

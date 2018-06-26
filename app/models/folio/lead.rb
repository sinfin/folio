# frozen_string_literal: true

module Folio
  class Lead < ApplicationRecord
    # Validations
    validates_format_of :email, with: ::Folio::EMAIL_REGEXP,
                                unless: :skip_email_validation?
    validates :note,
              presence: true,
              unless: :skip_note_validation?

    # Scopes
    default_scope { order(created_at: :desc) }
    scope :by_query, -> (q) {
      if q.present?
        args = ["%#{q}%"] * 2
        where('email ILIKE ? OR note ILIKE ?', *args)
      else
        where(nil)
      end
    }
    scope :handled, -> { with_state(:handled) }
    scope :not_handled, -> { with_state(:submitted) }

    state_machine initial: :submitted do
      event :handle do
        transition submitted: :handled
      end

      event :unhandle do
        transition handled: :submitted
      end
    end

    def title
      email.presence || phone.presence || self.class.model_name.human
    end

    private

      def skip_email_validation?
        false
      end

      def skip_note_validation?
        false
      end
  end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id              :integer          not null, primary key
#  email           :string
#  phone           :string
#  note            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#  url             :string
#  additional_data :json
#  state           :string           default("submitted")
#

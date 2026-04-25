# frozen_string_literal: true

module Folio::Ai::UserConcern
  extend ActiveSupport::Concern

  included do
    has_many :ai_user_instructions,
             class_name: "Folio::Ai::UserInstruction",
             foreign_key: :user_id,
             inverse_of: :user,
             dependent: :destroy
  end
end

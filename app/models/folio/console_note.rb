# frozen_string_literal: true

class Folio::ConsoleNote < Folio::ApplicationRecord
  include Folio::Positionable
  include Folio::BelongsToSite

  belongs_to :target, polymorphic: true

  belongs_to :created_by, class_name: "Folio::User",
                          inverse_of: :created_console_notes,
                          required: false

  belongs_to :closed_by, class_name: "Folio::User",
                         inverse_of: :closed_console_notes,
                         required: false

  validates :content,
            presence: true
  before_validation :set_target_site

  def set_target_site
    self.site = target&.site || Folio::Current.site
  end
end

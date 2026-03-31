# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  # Host apps that do not inherit from Folio::ApplicationRecord should include
  # Folio::FindOrFetch here to use find_or_fetch on application models.
  include Folio::FindOrFetch
  include Folio::Filterable
  include Folio::HtmlSanitization::Model
  include Folio::NillifyBlanks
  include Folio::ToLabel

  self.abstract_class = true
end

# frozen_string_literal: true

class Dummy::Page::WithFolioAttributes < Folio::Page
  has_folio_attributes "Dummy::AttributeType::PageAttributeType"
end

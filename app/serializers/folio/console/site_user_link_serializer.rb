# frozen_string_literal: true

class Folio::Console::SiteUserLinkSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :locked
end

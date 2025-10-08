# frozen_string_literal: true

class Folio::Console::ApplicationComponent < Folio::ApplicationComponent
  include Folio::Console::PreviewUrlFor
  include Folio::Console::UiHelper
  include Folio::StringHelper
end

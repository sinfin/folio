class FolioCell < Cell::ViewModel
  include ::Cell::Translation
  include ActionView::Helpers::TranslationHelper

  self.view_paths << "#{Folio::Engine.root}/app/cells"
end

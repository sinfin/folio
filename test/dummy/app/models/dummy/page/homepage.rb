# frozen_string_literal: true

class Dummy::Page::Homepage < Folio::Page
  include Folio::PerSiteSingleton

  def self.public_rails_path
    :root_path
  end

  def self.atoms_settings_skip_label_and_perex?
    true
  end
end

# frozen_string_literal: true

class Dummy::Ui::ConsolePreview::InvalidAtomComponent < ApplicationComponent
  def initialize(atom:, message: nil)
    @atom = atom
    @message = message
  end
end

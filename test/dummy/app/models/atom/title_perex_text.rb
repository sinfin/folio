# frozen_string_literal: true

module Atom
  class TitlePerexText < Folio::Atom::Base
    STRUCTURE = {
      title: :string,
      perex: :string,
      content: :string,
    }
  end
end

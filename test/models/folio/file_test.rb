# frozen_string_literal: true

require 'test_helper'

module Folio
  class FileTest < ActiveSupport::TestCase
    test 'touches placements and their models' do
      page = create(:folio_page)
      updated_at = page.updated_at

      image = create(:folio_image)
      page.images << image
      assert page.reload.updated_at > updated_at

      updated_at = page.updated_at
      assert image.reload.update!(tag_list: 'foo')
      assert page.reload.updated_at > updated_at
    end

    test 'touches page through atoms' do
      page = create(:folio_page)
      image = create(:folio_image)
      atom = create_atom(::Atom::SingleImage, placement: page, cover: image)

      atom_updated_at = atom.reload.updated_at
      page_updated_at = page.reload.updated_at

      assert image.reload.update!(tag_list: 'foo')
      assert atom.reload.updated_at > atom_updated_at
      assert page.reload.updated_at > page_updated_at
    end
  end
end

# == Schema Information
#
# Table name: folio_files
#
#  id              :integer          not null, primary key
#  file_uid        :string
#  file_name       :string
#  type            :string
#  thumbnail_sizes :text             default("--- {}\n")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  file_width      :integer
#  file_height     :integer
#  file_size       :integer
#  mime_type       :string(255)
#  additional_data :json
#
# Indexes
#
#  index_folio_files_on_type  (type)
#

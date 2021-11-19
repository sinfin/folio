# frozen_string_literal: true

class Folio::ContentTemplate::AasmEmailSubject < Folio::ContentTemplate
end

# == Schema Information
#
# Table name: folio_content_templates
#
#  id         :bigint(8)        not null, primary key
#  content    :text
#  position   :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  title      :string
#
# Indexes
#
#  index_folio_content_templates_on_position  (position)
#  index_folio_content_templates_on_type      (type)
#

# frozen_string_literal: true

class Folio::EmailTemplate < Folio::ApplicationRecord
  validates :title, :mailer, :subject, :body,
            presence: true

  validates :action,
            uniqueness: { scope: %i[mailer] },
            presence: true

  translates :subject, :body
end

# == Schema Information
#
# Table name: folio_email_templates
#
#  id         :bigint(8)        not null, primary key
#  title      :string
#  mailer     :string
#  action     :string
#  subject_en :string
#  body_en    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

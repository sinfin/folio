# frozen_string_literal: true

module Ahoy
  class Event < ActiveRecord::Base
    include Ahoy::Properties

    self.table_name = 'ahoy_events'

    belongs_to :visit
    belongs_to :account, class_name: 'Folio::Account', optional: true

    scope :ordered, -> { order(time: :asc) }
  end
end

# == Schema Information
#
# Table name: ahoy_events
#
#  id         :bigint(8)        not null, primary key
#  visit_id   :integer
#  account_id :bigint(8)
#  name       :string
#  properties :jsonb
#  time       :datetime
#
# Indexes
#
#  index_ahoy_events_on_account_id         (account_id)
#  index_ahoy_events_on_name_and_time      (name,time)
#  index_ahoy_events_on_visit_id_and_name  (visit_id,name)
#

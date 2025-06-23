# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::NodeTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node title: :string,
                content: :text,
                button_url_json: :url_json

    validates :title,
              presence: true
  end

  test "to_tiptap_node_hash" do
    node = Node.new(title: "foo",
                            content: "bar",
                            button_url_json: { href: "foo", label: "bar" })

    hash = node.to_tiptap_node_hash
    assert_equal "folio_node", hash["type"]
    assert_equal 1, hash["version"]
    assert_equal "Folio::Tiptap::NodeTest::Node", hash["attrs"]["type"]
    assert_equal "foo", hash["attrs"]["title"]
  end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id              :integer          not null, primary key
#  email           :string
#  phone           :string
#  note            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#  url             :string
#  additional_data :json
#  state           :string           default("submitted")
#  visit_id        :integer
#
# Indexes
#
#  index_folio_leads_on_visit_id  (visit_id)
#

# frozen_string_literal: true

class Folio::NestedFieldsComponent < Folio::ApplicationComponent
  attr_reader :g

  def initialize(f:, key:, add: true, destroy: true, position: true)
    @f = f
    @key = key
    @add = add
    @destroy = destroy
    @position = position
  end

  def data
    stimulus_controller("f-nested-fields",
                        values: {
                          key: @key,
                          sortableBound: false,
                        })
  end

  def new_object
    @f.object.class.reflect_on_association(@key).klass.new
  end
end

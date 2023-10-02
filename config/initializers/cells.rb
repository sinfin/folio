# frozen_string_literal: true

ActiveSupport.on_load(:action_view) do
  self.class_eval do
    def cell(name, model = nil, options = {}, &block)
      options[:context] ||= {}
      options[:context][:view] = self
      controller.cell(name, model, options, &block)
    end
  end
end

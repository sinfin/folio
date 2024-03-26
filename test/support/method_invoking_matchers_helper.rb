# frozen_string_literal: true

require "minitest/mock"

module MethodInvokingMatchersHelper
  private
    def expect_method_called_on(object:, method:, args: [], kwargs: {}, return_value: :not_passed, &block)
      if return_value == :not_passed
        return_value = (object.instance_of?(::Class) ? "call to #{object}.#{method}" : "call to #{object.class}##{method}") # rubocop:disable Layout/LineLength
      end

      mock_of_method = Minitest::Mock.new
      mock_of_method.expect :call, return_value, args, **kwargs

      result = object.stub(method, mock_of_method, &block)
      mock_of_method.verify
      result
    end

    def expect_no_method_called_on(obj, method, &block)
      obj.stub(method, ->(*_args) { raise "Unexpected call of :#{method} on #{obj.class.name}#{obj.to_json}" }, &block)
    end
end

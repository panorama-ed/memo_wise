# frozen_string_literal: true

RSpec.shared_context "with context for module methods via 'def self.'" do
  let(:module_with_memo) do
    Module.new do
      prepend MemoWise

      DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
        target: self,
        via: :self_dot
      )

      # Counter for calls to instance method '#with_keyword_args', see below.
      def instance_with_keyword_args_counter
        @instance_with_keyword_args_counter || 0
      end

      # See: "doesn't memoize instance methods when passed self: keyword"
      #
      # Used by that spec to verify that `memo_wise self: :with_keyword_args`
      # memoizes only the class method, and not this instance method sharing
      # the same name.
      def with_keyword_args(a:, b:) # rubocop:disable Naming/MethodParameterName
        @instance_with_keyword_args_counter =
          instance_with_keyword_args_counter + 1
        "instance_with_keyword_args_counter: a=#{a}, b=#{b}"
      end
    end
  end
end

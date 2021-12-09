# frozen_string_literal: true

RSpec.shared_context "with context for instance methods" do
  # an instance of a class with instance methods setup to test memoization
  let(:instance) { class_with_memo.new }

  # a class with instance methods setup to test memoization
  let(:class_with_memo) do
    Class.new do
      extend MemoWise

      DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
        target: self,
        via: :instance
      )

      # Counter for calls to a protected method
      def protected_memowise_method_counter
        @protected_memowise_method_counter || 0
      end

      # A memoized protected method - only makes sense as an instance method
      def protected_memowise_method
        @protected_memowise_method_counter = protected_memowise_method_counter + 1
        "protected_memowise_method"
      end
      protected :protected_memowise_method
      memo_wise :protected_memowise_method

      # Counter for calls to class method '.no_args', see below.
      def self.class_no_args_counter
        @class_no_args_counter || 0
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :no_args` memoizes only the
      # instance method, and not this class method sharing the same name.
      def self.no_args
        @class_no_args_counter = class_no_args_counter + 1
        "class_no_args"
      end

      # Counter for calls to class method '.with_one_positional_arg', see below.
      def self.class_one_positional_arg_counter
        @class_one_positional_arg_counter || 0
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :with_one_positional_arg`
      # memoizes only the instance method, and not this class method sharing
      # the same name.
      def self.with_one_positional_arg(a) # rubocop:disable Naming/MethodParameterName
        @class_one_positional_arg_counter = class_one_positional_arg_counter + 1
        "class_with_one_positional_arg: a=#{a}"
      end

      # Counter for calls to class method '.with_positional_args', see below.
      def self.class_positional_args_counter
        @class_positional_args_counter || 0
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :with_positional_args`
      # memoizes only the instance method, and not this class method sharing
      # the same name.
      def self.with_positional_args(a, b) # rubocop:disable Naming/MethodParameterName
        @class_positional_args_counter = class_positional_args_counter + 1
        "class_with_positional_args: a=#{a}, b=#{b}"
      end
    end
  end
end

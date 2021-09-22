# frozen_string_literal: true

RSpec.shared_context "with context for module methods via normal scope" do
  let(:module_with_memo) do
    Module.new do
      prepend MemoWise

      DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
        target: self,
        via: :instance
      )

      # Counter for calls to module method '.no_args', see below.
      def self.module_no_args_counter
        @module_no_args_counter || 0 # rubocop:disable RSpec/InstanceVariable
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :no_args` memoizes only the
      # instance method, and not this module method sharing the same name.
      def self.no_args
        @module_no_args_counter = module_no_args_counter + 1
        "module_no_args"
      end

      # Counter for calls to module method '.with_one_positional_arg', see below.
      def self.module_one_positional_arg_counter
        @module_one_positional_arg_counter || 0 # rubocop:disable RSpec/InstanceVariable
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :with_one_positional_arg`
      # memoizes only the instance method, and not this module method sharing
      # the same name.
      def self.with_one_positional_arg(a) # rubocop:disable Naming/MethodParameterName
        @module_one_positional_arg_counter = module_one_positional_arg_counter + 1
        "module_with_one_positional_arg: a=#{a}"
      end

      # Counter for calls to module method '.with_positional_args', see below.
      def self.module_positional_args_counter
        @module_positional_args_counter || 0 # rubocop:disable RSpec/InstanceVariable
      end

      # See: "with non-memoized method with same name as memoized method"
      #
      # Used by that spec to verify that `memo_wise :with_positional_args`
      # memoizes only the instance method, and not this module method sharing
      # the same name.
      def self.with_positional_args(a, b) # rubocop:disable Naming/MethodParameterName
        @module_positional_args_counter = module_positional_args_counter + 1
        "module_with_positional_args: a=#{a}, b=#{b}"
      end
    end
  end
end

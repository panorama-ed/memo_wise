# frozen_string_literal: true

##
# Module to define methods for use in testing, as one of:
#   * Instance methods
#   * Class methods defined via: 'def self.foo ...'
#   * Class methods defined via: 'class << self; def foo ...'
#
# NOTE: To define *class* methods for testing via 'class << self', please use
# the `:instance` option and call it within the 'class << self' scope.
##
module DefineMethodsForTestingMemoWise # rubocop:disable Metrics/ModuleLength
  # Define a set of methods for testing (ex: `with_positional_args(a, b)`).
  #
  # @param target [Class, Module]
  #   Class scope in which to evaluate method definitions
  #
  # @param via [:instance, :self_dot]
  #   How to define the methods:
  #     * `:instance` -- Instance method definition via `def foo ...`
  #     * `:self_dot` -- Class method definition via `def self.foo ...`
  #
  def self.define_methods_for_testing_memo_wise(target:, via:)
    # Raise errors in case this test setup method is used incorrectly, but
    # exclude from SimpleCov code coverage.

    # :nocov:
    unless target.is_a?(Module)
      raise ArgumentError, "Not a Class or Module: #{target.inspect}"
    end

    unless %i[instance self_dot].include?(via)
      raise ArgumentError, "Unknown value for 'via': #{via}"
    end # rubocop:disable Layout/EmptyLineAfterGuardClause
    # :nocov:

    self_prefix = via == :self_dot ? "self." : ""
    self_kw_arg = via == :self_dot ? "self: " : ""
    self_class_method = via == :self_dot ? "_class_method" : ""

    # rubocop:disable Style/DocumentDynamicEvalDefinition
    target.module_eval <<~END_OF_METHOD, __FILE__, __LINE__ + 1
      def #{self_prefix}no_args_counter
        @no_args_counter || 0
      end

      def #{self_prefix}with_positional_args_counter
        @with_positional_args_counter || 0
      end

      def #{self_prefix}with_positional_and_splat_args_counter
        @with_positional_and_splat_args_counter || 0
      end

      def #{self_prefix}with_keyword_args_counter
        @with_keyword_args_counter || 0
      end

      def #{self_prefix}with_keyword_and_double_splat_args_counter
        @with_keyword_and_double_splat_args_counter || 0
      end

      def #{self_prefix}with_positional_and_keyword_args_counter
        @with_positional_and_keyword_args_counter || 0
      end

      def #{self_prefix}with_positional_splat_keyword_and_double_splat_args_counter
        @with_positional_splat_keyword_and_double_splat_args_counter || 0
      end

      def #{self_prefix}special_chars_counter
        @special_chars_counter || 0
      end

      def #{self_prefix}false_method_counter
        @false_method_counter || 0
      end

      def #{self_prefix}true_method_counter
        @true_method_counter || 0
      end

      def #{self_prefix}nil_method_counter
        @nil_method_counter || 0
      end

      def #{self_prefix}private_memowise_method_counter
        @private_memowise_method_counter || 0
      end

      def #{self_prefix}public_memowise_method_counter
        @public_memowise_method_counter || 0
      end

      def #{self_prefix}proc_method_counter
        @proc_method_counter || 0
      end

      def #{self_prefix}no_args
        @no_args_counter = no_args_counter + 1
        "no_args"
      end
      memo_wise #{self_kw_arg}:no_args

      def #{self_prefix}with_positional_args(a, b) # rubocop:disable Naming/MethodParameterName
        @with_positional_args_counter = with_positional_args_counter + 1
        "with_positional_args: a=\#{a}, b=\#{b}"
      end
      memo_wise #{self_kw_arg}:with_positional_args

      def #{self_prefix}with_positional_and_splat_args(a, *args) # rubocop:disable Naming/MethodParameterName
        @with_positional_and_splat_args_counter =
          with_positional_and_splat_args_counter + 1
        "with_positional_and_splat_args: a=\#{a}, args=\#{args}"
      end
      memo_wise #{self_kw_arg}:with_positional_and_splat_args

      def #{self_prefix}with_keyword_args(a:, b:) # rubocop:disable Naming/MethodParameterName
        @with_keyword_args_counter = with_keyword_args_counter + 1
        "with_keyword_args: a=\#{a}, b=\#{b}"
      end
      memo_wise #{self_kw_arg}:with_keyword_args

      def #{self_prefix}with_keyword_and_double_splat_args(a:, **kwargs) # rubocop:disable Naming/MethodParameterName
        @with_keyword_and_double_splat_args_counter =
          with_keyword_and_double_splat_args_counter + 1
        "with_keyword_and_double_splat_args: a=\#{a}, kwargs=\#{kwargs}"
      end
      memo_wise #{self_kw_arg}:with_keyword_and_double_splat_args

      def #{self_prefix}with_positional_and_keyword_args(a, b:) # rubocop:disable Naming/MethodParameterName
        @with_positional_and_keyword_args_counter =
          with_positional_and_keyword_args_counter + 1
        "with_positional_and_keyword_args: a=\#{a}, b=\#{b}"
      end
      memo_wise #{self_kw_arg}:with_positional_and_keyword_args

      def #{self_prefix}with_positional_splat_keyword_and_double_splat_args(
        a, # rubocop:disable Naming/MethodParameterName
        *args,
        b:, # rubocop:disable Naming/MethodParameterName
        **kwargs
      )
        @with_positional_splat_keyword_and_double_splat_args_counter =
          with_positional_splat_keyword_and_double_splat_args_counter + 1
        "with_positional_splat_keyword_and_double_splat_args: "\
          "a=\#{a}, args=\#{args} b=\#{b} kwargs=\#{kwargs}"
      end
      memo_wise #{self_kw_arg}:with_positional_splat_keyword_and_double_splat_args

      def #{self_prefix}special_chars?
        @special_chars_counter = special_chars_counter + 1
        "special_chars?"
      end
      memo_wise #{self_kw_arg}:special_chars?

      def #{self_prefix}false_method
        @false_method_counter = false_method_counter + 1
        false
      end
      memo_wise #{self_kw_arg}:false_method

      def #{self_prefix}true_method
        @true_method_counter = true_method_counter + 1
        true
      end
      memo_wise #{self_kw_arg}:true_method

      def #{self_prefix}nil_method
        @nil_method_counter = nil_method_counter + 1
        nil
      end
      memo_wise #{self_kw_arg}:nil_method

      def #{self_prefix}private_memowise_method
        @private_memowise_method_counter = private_memowise_method_counter + 1
        "private_memowise_method"
      end
      private#{self_class_method} :private_memowise_method
      memo_wise #{self_kw_arg}:private_memowise_method

      def #{self_prefix}public_memowise_method
        @public_memowise_method_counter = public_memowise_method_counter + 1
        "public_memowise_method"
      end
      memo_wise #{self_kw_arg}:public_memowise_method
      public#{self_class_method} :public_memowise_method

      def #{self_prefix}unmemoized_method; end

      def #{self_prefix}proc_method(proc)
        @proc_method_counter = proc_method_counter + 1
        proc.call
      end
      memo_wise #{self_kw_arg}:proc_method

      def #{self_prefix}explicit_block_method(&block) # rubocop:disable Lint/UnusedMethodArgument
        yield
      end
      memo_wise #{self_kw_arg}:explicit_block_method

      def #{self_prefix}implicit_block_method
        yield
      end
      memo_wise #{self_kw_arg}:implicit_block_method
    END_OF_METHOD
    # rubocop:enable Style/DocumentDynamicEvalDefinition
  end
end

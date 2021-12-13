# frozen_string_literal: true

module MemoWise
  class InternalAPI
    # Create initial mutable state to store memoized values if it doesn't
    # already exist
    #
    # @param [Object] obj
    #   Object in which to create mutable state to store future memoized values
    #
    # @return [Object] the passed-in obj
    def self.create_memo_wise_state!(obj)
      # `@_memo_wise` stores memoized results of method calls in a hash keyed on
      # method name. The structure is slightly different for different types of
      # methods. It looks like:
      #   {
      #     zero_arg_method_name: :memoized_result,
      #     single_arg_method_name: { arg1 => :memoized_result, ... },
      #
      #     # Surprisingly, this is faster than a single top-level hash key of: [:multi_arg_method_name, arg1, arg2]
      #     multi_arg_method_name: { [arg1, arg2] => :memoized_result, ... }
      #   }
      obj.instance_variable_set(:@_memo_wise, {}) unless obj.instance_variable_defined?(:@_memo_wise)

      obj
    end

    NONE = :none
    ONE_REQUIRED_POSITIONAL = :one_required_positional
    ONE_REQUIRED_KEYWORD = :one_required_keyword
    MULTIPLE_REQUIRED = :multiple_required
    SPLAT = :splat
    DOUBLE_SPLAT = :double_splat
    SPLAT_AND_DOUBLE_SPLAT = :splat_and_double_splat

    # @param method [UnboundMethod] a method to categorize based on the types of
    #   arguments it has
    # @return [Symbol] one of:
    #   - :none (example: `def foo`)
    #   - :one_required_positional (example: `def foo(a)`)
    #   - :one_required_keyword (example: `def foo(a:)`)
    #   - :multiple_required (examples: `def foo(a, b)`, `def foo(a:, b:)`, `def foo(a, b:)`)
    #   - :splat (examples: `def foo(a=1)`, `def foo(a, *b)`)
    #   - :double_splat (examples: `def foo(a: 1)`, `def foo(a:, **b)`)
    #   - :splat_and_double_splat (examples: `def foo(a=1, b: 2)`, `def foo(a=1, **b)`, `def foo(*a, **b)`)
    def self.method_arguments(method)
      return NONE if method.arity.zero?

      parameters = method.parameters.map(&:first)

      if parameters == [:req]
        ONE_REQUIRED_POSITIONAL
      elsif parameters == [:keyreq]
        ONE_REQUIRED_KEYWORD
      elsif parameters.all? { |type| type == :req || type == :keyreq }
        MULTIPLE_REQUIRED
      elsif parameters & %i[req opt rest] == parameters.uniq
        SPLAT
      elsif parameters & %i[keyreq key keyrest] == parameters.uniq
        DOUBLE_SPLAT
      else
        SPLAT_AND_DOUBLE_SPLAT
      end
    end

    # @param method [UnboundMethod] a method being memoized
    # @return [String] the arguments string to use when defining our new
    #   memoized version of the method
    def self.args_str(method)
      case method_arguments(method)
      when SPLAT then "*args"
      when DOUBLE_SPLAT then "**kwargs"
      when SPLAT_AND_DOUBLE_SPLAT then "*args, **kwargs"
      when ONE_REQUIRED_POSITIONAL, ONE_REQUIRED_KEYWORD, MULTIPLE_REQUIRED
        method.parameters.map do |type, name|
          "#{name}#{':' if type == :keyreq}"
        end.join(", ")
      else
        raise ArgumentError, "Unexpected arguments for #{method.name}"
      end
    end

    # @param method [UnboundMethod] a method being memoized
    # @return [String] the arguments string to use when calling the original
    #   method in our new memoized version of the method, i.e. when setting a
    #   memoized value
    def self.call_str(method)
      case method_arguments(method)
      when SPLAT then "*args"
      when DOUBLE_SPLAT then "**kwargs"
      when SPLAT_AND_DOUBLE_SPLAT then "*args, **kwargs"
      when ONE_REQUIRED_POSITIONAL, ONE_REQUIRED_KEYWORD, MULTIPLE_REQUIRED
        method.parameters.map do |type, name|
          type == :req ? name : "#{name}: #{name}"
        end.join(", ")
      else
        raise ArgumentError, "Unexpected arguments for #{method.name}"
      end
    end

    # @param method [UnboundMethod] a method being memoized
    # @return [String] the string to use as a hash key when looking up a
    #   memoized value, based on the method's arguments
    def self.key_str(method)
      case method_arguments(method)
      when SPLAT then "args"
      when DOUBLE_SPLAT then "kwargs"
      when SPLAT_AND_DOUBLE_SPLAT then "[args, kwargs]"
      when MULTIPLE_REQUIRED then "[#{method.parameters.map(&:last).join(', ')}]"
      else
        raise ArgumentError, "Unexpected arguments for #{method.name}"
      end
    end

    # Find the original class for which the given class is the corresponding
    # "singleton class".
    #
    # See https://stackoverflow.com/questions/54531270/retrieve-a-ruby-object-from-its-singleton-class
    #
    # @param klass [Class]
    #   Singleton class to find the original class of
    #
    # @return Class
    #   Original class for which `klass` is the singleton class.
    #
    # @raise ArgumentError
    #   Raises if `klass` is not a singleton class.
    #
    def self.original_class_from_singleton(klass)
      raise ArgumentError, "Must be a singleton class: #{klass.inspect}" unless klass.singleton_class?

      # Since we call this method a lot, we memoize the results. This can have a
      # huge impact; for example, in our test suite this drops our test times
      # from over five minutes to just a few seconds.
      @original_class_from_singleton ||= {}

      # Search ObjectSpace
      #   * 1:1 relationship of singleton class to original class is documented
      #   * Performance concern: searches all Class objects
      #     But, only runs at load time and results are memoized
      @original_class_from_singleton[klass] ||= ObjectSpace.each_object(Module).find do |cls|
        cls.singleton_class == klass
      end
    end

    # Convention we use for renaming the original method when we replace with
    # the memoized version in {MemoWise.memo_wise}.
    #
    # @param method_name [Symbol]
    #   Name for which to return the renaming for the original method
    #
    # @return [Symbol]
    #   Renamed method to use for the original method with name `method_name`
    #
    def self.original_memo_wised_name(method_name)
      :"_memo_wise_original_#{method_name}"
    end

    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization;
    #   the `InternalAPI` *instance* methods will refer to this `target` class.
    def initialize(target)
      @target = target
    end

    # @return [Class, Module]
    attr_reader :target

    # Returns visibility of an instance method defined on class `target`.
    #
    # @param method_name [Symbol]
    #   Name of existing *instance* method find the visibility of.
    #
    # @return [:private, :protected, :public]
    #   Visibility of existing instance method of the class.
    #
    # @raise ArgumentError
    #   Raises `ArgumentError` unless `method_name` is a `Symbol` corresponding
    #   to an existing **instance** method defined on `klass`.
    #
    def method_visibility(method_name)
      if target.private_method_defined?(method_name)
        :private
      elsif target.protected_method_defined?(method_name)
        :protected
      elsif target.public_method_defined?(method_name)
        :public
      else
        raise ArgumentError, "#{method_name.inspect} must be a method on #{target}"
      end
    end

    # Validates that `method_name` is a method defined by a call to {.memo_wise},
    # and returns the method
    #
    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization.
    #
    # @param method_name [Symbol]
    #   Name of method that should have been setup with {.memo_wise}
    def memo_wised_method(method_name)
      klass = target_class

      method_defined = klass.method_defined?(method_name) || klass.private_method_defined?(method_name)

      unless method_defined
        raise ArgumentError, "#{method_name} is not a memo_wised method"
      end

      method = klass.instance_method(method_name)

      unless method.owner == klass.memo_wise_module && method.super_method
        raise ArgumentError, "#{method_name} is not a memo_wised method"
      end

      method
    end

    # @return [Class] where we look for method definitions
    def target_class
      if target.instance_of?(Class)
        # A class's methods are defined in its singleton class
        target.singleton_class
      else
        # An object's methods are defined in its class
        target.class
      end
    end
  end
end

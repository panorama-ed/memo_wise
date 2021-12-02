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
      # `@_memo_wise` stores memoized results of method calls. The structure is
      # slightly different for different types of methods. It looks like:
      #   [
      #     :memoized_result, # For method 0 (which takes no arguments)
      #     { arg1 => :memoized_result, ... }, # For method 1 (which takes an argument)
      #     { [arg1, arg2] => :memoized_result, ... } # For method 2 (which takes multiple arguments)
      #   ]
      # This is a faster alternative to:
      #   {
      #     zero_arg_method_name: :memoized_result,
      #     single_arg_method_name: { arg1 => :memoized_result, ... },
      #
      #     # Surprisingly, this is faster than a single top-level hash key of: [:multi_arg_method_name, arg1, arg2]
      #     multi_arg_method_name: { [arg1, arg2] => :memoized_result, ... }
      #   }
      # because we can give each method its own array index at load time and
      # perform that array lookup more quickly than a hash lookup by method
      # name.
      obj.instance_variable_set(:@_memo_wise, []) unless obj.instance_variable_defined?(:@_memo_wise)

      # For zero-arity methods, memoized values are stored in the `@_memo_wise`
      # array. Arrays do not differentiate between "unset" and "set to nil" and
      # so to handle this case we need another array to store sentinels and
      # store `true` at indexes for which a zero-arity method has been memoized.
      # `@_memo_wise_sentinels` looks like:
      #   [
      #     true, # A zero-arity method's result has been memoized
      #     nil, # A zero-arity method's result has not been memoized
      #     nil, # A one-arity method will always correspond to `nil` here
      #     ...
      #   ]
      # NOTE: Because `@_memo_wise` stores memoized values for more than just
      # zero-arity methods, the `@_memo_wise_sentinels` array can end up being
      # sparse (see above), even when all methods' memoized values have been
      # stored. If this becomes an issue we could store a separate index for
      # zero-arity methods to make every element in `@_memo_wise_sentinels`
      # correspond to a zero-arity method.
      # NOTE: Surprisingly, lookups on an array of `true` and `nil` values
      # appear to outperform even bitwise operators on integers (as of Ruby
      # 3.0.2), allowing us to avoid more complex sentinel structures.
      unless obj.instance_variable_defined?(:@_memo_wise_sentinels)
        obj.instance_variable_set(:@_memo_wise_sentinels, [])
      end

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

    # @param method_name [Symbol] the name of the memoized method
    # @return [Integer] the array index in `@_memo_wise_indices` to use to find
    #   the memoization data for the given method
    def self.index(target, method_name)
      klass = target_class(target)
      indices = klass.instance_variable_get(:@_memo_wise_indices)
      indices&.[](method_name) || next_index!(klass, method_name)
    end

    # Returns visibility of an instance method defined on class `target`.
    #
    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization.
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
    def self.method_visibility(target, method_name)
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

    # Validates that {.memo_wise} has already been called on `method_name`.
    #
    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization.
    #
    # @param method_name [Symbol]
    #   Name of method to validate has already been setup with {.memo_wise}
    def self.validate_memo_wised!(target, method_name)
      original_name = original_memo_wised_name(method_name)

      unless target_class(target).private_method_defined?(original_name)
        raise ArgumentError, "#{method_name} is not a memo_wised method"
      end
    end

    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization.
    # @return [Class] where we look for method definitions
    def self.target_class(target)
      if target.instance_of?(Class)
        # A class's methods are defined in its singleton class
        target.singleton_class
      else
        # An object's methods are defined in its class
        target.class
      end
    end
    private_class_method :target_class

    # Increment the class's method index counter, and return an index to use for
    # the given method name.
    #
    # @param klass [Class]
    #   Original class on which a method is being memoized
    #
    # @param method_name [Symbol]
    #   The name of the method being memoized
    #
    # @return [Integer]
    #   The index within `@_memo_wise` to store the method's memoized results
    def self.next_index!(klass, method_name)
      # `@_memo_wise_indices` stores the `@_memo_wise` indices of different
      # method names. We only use this data structure when resetting or
      # presetting memoization. It looks like:
      #   {
      #     single_arg_method_name: 0,
      #     other_single_arg_method_name: 1
      #   }
      memo_wise_indices = klass.instance_variable_get(:@_memo_wise_indices)
      memo_wise_indices ||= klass.instance_variable_set(:@_memo_wise_indices, {})

      index = klass.instance_variable_get(:@_memo_wise_index_counter) || 0
      memo_wise_indices[method_name] = index
      klass.instance_variable_set(:@_memo_wise_index_counter, index + 1)

      index
    end
    private_class_method :next_index!
  end
end

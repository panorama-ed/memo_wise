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
      # `@_memo_wise` and `@_memo_wise_single_argument` store memoized results
      # of method calls. For performance reasons, the structure differs for
      # different types of methods.
      #
      # `@_memo_wise` looks like:
      #   {
      #     no_args_method_name: :memoized_result,
      #     [:multi_arg_method_name, arg1, arg2].hash => :memoized_result
      #   }
      #
      # `@_memo_wise_single_argument` looks like:
      #   [
      #     { arg1 => :memoized_result, ... }, # For method 1
      #     { arg1 => :memoized_result, ... }, # For method 2
      #   ]
      # This is essentially a faster alternative to:
      #   {
      #     single_arg_method_name: { arg1 => :memoized_result, ... }
      #   }
      # because we can give each single-argument method its own array index at
      # load time and perform that array lookup more quickly than a hash lookup
      # by method name.
      unless obj.instance_variables.include?(:@_memo_wise)
        obj.instance_variable_set(:@_memo_wise, {})
      end
      unless obj.instance_variables.include?(:@_memo_wise_single_argument)
        obj.instance_variable_set(:@_memo_wise_single_argument, [])
      end

      # `@_memo_wise_hashes` stores the `Array#hash` values for each key in
      # `@_memo_wise` that represents a multi-argument method call. We only use
      # this data structure when resetting memoization for an entire method. It
      # looks like:
      #   {
      #     multi_arg_method_name: Set[
      #       [:multi_arg_method_name, arg1, arg2].hash,
      #       [:multi_arg_method_name, arg1, arg3].hash,
      #       ...
      #     ],
      #     ...
      #   }
      unless obj.instance_variables.include?(:@_memo_wise_hashes)
        obj.instance_variable_set(:@_memo_wise_hashes, {})
      end

      obj
    end

    def self.method_arguments(method)
      return :none if method.arity.zero?

      parameters = method.parameters.map(&:first)

      if parameters == [:req]
        :one_required_positional
      elsif parameters == [:keyreq]
        :one_required_keyword
      elsif parameters.all? { |type| type == :req || type == :keyreq }
        :multiple_required
      elsif parameters & %i[req opt rest] == parameters.uniq
        :splat
      elsif parameters & %i[keyreq key keyrest] == parameters.uniq
        :double_splat
      elsif parameters & %i[req opt rest keyreq key keyrest] == parameters.uniq
        :splat_and_double_splat
      else
        :unknown
      end
    end

    def self.args_str(method)
      case method_arguments(method)
      when :splat then "*args"
      when :double_splat then "**kwargs"
      when :splat_and_double_splat then "*args, **kwargs"
      when :one_required_positional, :one_required_keyword, :multiple_required
        method.parameters.map do |type, name|
          "#{name}#{':' if type == :keyreq}"
        end.join(", ")
      end
    end

    def self.call_str(method)
      case method_arguments(method)
      when :splat_and_double_splat then "*args, **kwargs"
      when :one_required_positional, :one_required_keyword, :multiple_required
        method.parameters.map do |type, name|
          type == :req ? name : "#{name}: #{name}"
        end.join(", ")
      end
    end

    def self.key_str(method)
      case method_arguments(method)
      when :splat then "args.hash"
      when :double_splat then "kwargs.hash"
      when :splat_and_double_splat then "[:#{method.name}, args, kwargs].hash"
      when :multiple_required
        "[:#{method.name}, #{method.parameters.map(&:last).join(', ')}].hash"
      end
    end

    # Determine whether `method` takes any *positional* args.
    #
    # These are the types of positional args:
    #
    #   * *Required* -- ex: `def foo(a)`
    #   * *Optional* -- ex: `def foo(b=1)`
    #   * *Splatted* -- ex: `def foo(*c)`
    #
    # @param method [Method, UnboundMethod]
    #   Arguments of this method will be checked
    #
    # @return [Boolean]
    #   Return `true` if `method` accepts one or more positional arguments
    #
    # @example
    #   class Example
    #     def no_args
    #     end
    #
    #     def position_arg(a)
    #     end
    #   end
    #
    #   MemoWise::InternalAPI.
    #     has_arg?(Example.instance_method(:no_args)) #=> false
    #
    #   MemoWise::InternalAPI.
    #     has_arg?(Example.instance_method(:position_arg)) #=> true
    #
    def self.has_arg?(method) # rubocop:disable Naming/PredicateName
      method.parameters.any? do |param, _|
        param == :req || param == :opt || param == :rest
      end
    end

    # Determine whether `method` takes any *keyword* args.
    #
    # These are the types of keyword args:
    #
    #   * *Keyword Required* -- ex: `def foo(a:)`
    #   * *Keyword Optional* -- ex: `def foo(b: 1)`
    #   * *Keyword Splatted* -- ex: `def foo(**c)`
    #
    # @param method [Method, UnboundMethod]
    #   Arguments of this method will be checked
    #
    # @return [Boolean]
    #   Return `true` if `method` accepts one or more keyword arguments
    #
    # @example
    #   class Example
    #     def position_args(a, b=1)
    #     end
    #
    #     def keyword_args(a:, b: 1)
    #     end
    #   end
    #
    #   MemoWise::InternalAPI.
    #     has_kwarg?(Example.instance_method(:position_args)) #=> false
    #
    #   MemoWise::InternalAPI.
    #     has_kwarg?(Example.instance_method(:keyword_args)) #=> true
    #
    def self.has_kwarg?(method) # rubocop:disable Naming/PredicateName
      method.parameters.any? do |param, _|
        param == :keyreq || param == :key || param == :keyrest
      end
    end

    # Determine whether `method` takes only *required* args.
    #
    # These are the types of required args:
    #
    #   * *Required* -- ex: `def foo(a)`
    #   * *Keyword Required* -- ex: `def foo(a:)`
    #
    # @param method [Method, UnboundMethod]
    #   Arguments of this method will be checked
    #
    # @return [Boolean]
    #   Return `true` if `method` accepts only required arguments
    #
    # @example
    #   class Ex
    #     def optional_args(a=1, b: 1)
    #     end
    #
    #     def required_args(a, b:)
    #     end
    #   end
    #
    #   MemoWise::InternalAPI.
    #     has_only_required_args?(Ex.instance_method(:optional_args))
    #     #=> false
    #
    #   MemoWise::InternalAPI.
    #     has_only_required_args?(Ex.instance_method(:required_args))
    #     #=> true
    def self.has_only_required_args?(method) # rubocop:disable Naming/PredicateName
      method.parameters.all? { |type, _| type == :req || type == :keyreq }
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
      unless klass.singleton_class?
        raise ArgumentError, "Must be a singleton class: #{klass.inspect}"
      end

      # Search ObjectSpace
      #   * 1:1 relationship of singleton class to original class is documented
      #   * Performance concern: searches all Class objects
      #     But, only runs at load time
      ObjectSpace.each_object(Module).find do |cls|
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

    def index(method_name)
      indices = target.class.instance_variable_get(:@_memo_wise_indices) ||
                target.singleton_class.instance_variable_get(:@_memo_wise_indices) || # rubocop:disable Layout/LineLength
                target.instance_variable_get(:@_memo_wise_indices)
      indices[method_name]
    end

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
        raise ArgumentError,
              "#{method_name.inspect} must be a method on #{target}"
      end
    end

    # Validates that {.memo_wise} has already been called on `method_name`.
    #
    # @param method_name [Symbol]
    #   Name of method to validate has already been setup with {.memo_wise}
    def validate_memo_wised!(method_name)
      original_name = self.class.original_memo_wised_name(method_name)

      unless target_class.private_method_defined?(original_name)
        raise ArgumentError, "#{method_name} is not a memo_wised method"
      end
    end

    private

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

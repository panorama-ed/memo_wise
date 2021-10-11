# frozen_string_literal: true
require "memo_wise/memo_wise_methods_module_builder"

module MemoWise
  class InternalAPI
    def self.create_internal_module(target)
      MemoWiseMethodsModuleBuilder.build.tap do |mod|
        target.prepend(target.const_set(:MemoWiseMethodsModule, mod))
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

    # @param target [Class, Module]
    #   The class to which we are prepending MemoWise to provide memoization;
    #   the `InternalAPI` *instance* methods will refer to this `target` class.
    def initialize(target)
      @target = target
    end

    # @return [Class, Module]
    attr_reader :target

    # Returns the "fetch key" for the given `method_name` and parameters, to be
    # used to lookup the memoized results specifically for this method and these
    # parameters.
    #
    # @param method_name [Symbol]
    #   Name of method to derive the "fetch key" for, with given parameters.
    # @param args [Array]
    #   Zero or more positional parameters
    # @param kwargs [Hash]
    #   Zero or more keyword parameters
    #
    # @return [Array, Hash, Object]
    #   Returns one of:
    #     - An `Array` if only positional parameters.
    #     - A nested `Array<Array, Hash>` if *both* positional and keyword.
    #     - A `Hash` if only keyword parameters.
    #     - A single object if there is only a single parameter.
    def fetch_key(method, *args, **kwargs)
      if MemoWise::InternalAPI.has_only_required_args?(method)
        key = method.parameters.map.with_index do |(type, name), index|
          type == :req ? args[index] : kwargs[name]
        end
        key.size == 1 ? key.first : [method.name, *key].hash
      else
        has_arg = MemoWise::InternalAPI.has_arg?(method)

        if has_arg && MemoWise::InternalAPI.has_kwarg?(method)
          [method.name, args, kwargs].hash
        elsif has_arg
          args.hash
        else
          kwargs.hash
        end
      end
    end

    # Returns whether the given method should use an array's hash value as the
    # cache lookup key. See the comments in `.create_memo_wise_state!` for an
    # example.
    #
    # @param method_name [Symbol]
    #   Name of memoized method we're checking the implementation of
    #
    # @return [Boolean] true iff the method uses a hashed cache key; false
    #   otherwise
    def use_hashed_key?(method)
      if MemoWise::InternalAPI.has_arg?(method) &&
         MemoWise::InternalAPI.has_kwarg?(method)
        return true
      end

      MemoWise::InternalAPI.has_only_required_args?(method) &&
        method.parameters.size > 1
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
      mod = target_class.memo_wise_module

      unless mod.method_defined?(method_name) || mod.private_method_defined?(method_name)
        raise ArgumentError, "#{method_name} is not a memo_wised method"
      end
    end

    def define_memo_wise_method(method, visibility)
      method_name = method.name

      # Zero-arg methods can use simpler/more performant logic because the
      # hash key is just the method name.
      if method.arity.zero?
        define_zero_param_method(method_name)
      else
        args_str, call_str, fetch_key, fetch_key_init = setup_multi_param_method_args(method)

        if use_hashed_key?(method)
          define_multi_param_hashed_key_method(method_name, args_str, call_str, fetch_key_init)
        else
          define_multi_param_method(method_name, args_str, call_str, fetch_key, fetch_key_init)
        end
      end

      target.memo_wise_module.send(visibility, method_name)
    end

    private

    def define_zero_param_method(method_name)
      target.memo_wise_module.module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          output = _memo_wise[:#{method_name}]
          if output || _memo_wise.key?(:#{method_name})
            output
          else
            _memo_wise[:#{method_name}] = super(&nil)
          end
        end
      RUBY
    end

    def setup_multi_param_method_args(method)
      if self.class.has_only_required_args?(method)
        args_str = method.parameters.map do |type, name|
          "#{name}#{':' if type == :keyreq}"
        end.join(", ")
        args_str = "(#{args_str})"
        call_str = method.parameters.map do |type, name|
          type == :req ? name : "#{name}: #{name}"
        end.join(", ")
        call_str = "(#{call_str})"
        fetch_key_params = method.parameters.map(&:last)
        if fetch_key_params.size > 1
          fetch_key_init = "[:#{method.name}, #{fetch_key_params.join(', ')}].hash"
        else
          fetch_key = fetch_key_params.first.to_s
        end
      else
        # If our method has arguments, we need to separate out our handling
        # of normal args vs. keyword args due to the changes in Ruby 3.
        # See: <link>
        # By only including logic for *args, **kwargs when they are used in
        # the method, we can avoid allocating unnecessary arrays and hashes.
        has_arg = self.class.has_arg?(method)

        if has_arg && self.class.has_kwarg?(method)
          args_str = "(*args, **kwargs)"
          fetch_key_init = "[:#{method.name}, args, kwargs].hash"
        elsif has_arg
          args_str = "(*args)"
          fetch_key_init = "args.hash"
        else
          args_str = "(**kwargs)"
          fetch_key_init = "kwargs.hash"
        end
      end

      [args_str, call_str || args_str, fetch_key || "key", fetch_key_init]
    end

    def define_multi_param_hashed_key_method(method_name, args_str, call_str, fetch_key_init)
      target.memo_wise_module.module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}#{args_str}
          key = #{fetch_key_init}
          output = _memo_wise[key]
          if output || _memo_wise.key?(key)
            output
          else
            hashes = (_memo_wise_hashes[:#{method_name}] ||= Set.new)
            hashes << key
            _memo_wise[key] = super#{call_str}
          end
        end
      RUBY
    end

    def define_multi_param_method(method_name, args_str, call_str, fetch_key, fetch_key_init)
      fetch_key_init_line = "key = #{fetch_key_init}" if fetch_key_init
      target.memo_wise_module.module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}#{args_str}
          hash = (_memo_wise[:#{method_name}] ||= {})
          #{fetch_key_init_line}
          output = hash[#{fetch_key}]
          if output || hash.key?(#{fetch_key})
            output
          else
            hash[#{fetch_key}] = super#{call_str}
          end
        end
      RUBY
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

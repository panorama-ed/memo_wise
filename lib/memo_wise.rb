# frozen_string_literal: true

require "set"

require "memo_wise/internal_api"
require "memo_wise/version"

# MemoWise is the wise choice for memoization in Ruby.
#
# - **Q:** What is *memoization*?
# - **A:** [via Wikipedia](https://en.wikipedia.org/wiki/Memoization):
#
#          [Memoization is] an optimization technique used primarily to speed up
#          computer programs by storing the results of expensive function
#          calls and returning the cached result when the same inputs occur
#          again.
#
# To start using MemoWise in a class or module:
#
#   1. Add `extend MemoWise` to the top of the class or module
#   2. Call {.memo_wise} to implement memoization for a given method
#
# **See Also:**
#
#   - {.memo_wise} for API and usage examples.
#   - {file:README.md} for general project information.
#
module MemoWise
  ##
  # @!method self.memo_wise(method_name)
  #   Implements memoization for the given method name.
  #
  #   - **Q:** What does it mean to "implement memoization"?
  #   - **A:** To wrap the original method such that, for any given set of
  #            arguments, the original method will be called at most *once*. The
  #            result of that call will be stored on the object. All future
  #            calls to the same method with the same set of arguments will then
  #            return that saved result.
  #
  #   Methods which implicitly or explicitly take block arguments cannot be
  #   memoized.
  #
  #   @param method_name [Symbol]
  #     Name of method for which to implement memoization.
  #
  #   @return [void]
  #
  #   @example
  #     class Example
  #       extend MemoWise
  #
  #       def method_to_memoize(x)
  #         @method_called_times = (@method_called_times || 0) + 1
  #       end
  #       memo_wise :method_to_memoize
  #     end
  #
  #     ex = Example.new
  #
  #     ex.method_to_memoize("a") #=> 1
  #     ex.method_to_memoize("a") #=> 1
  #
  #     ex.method_to_memoize("b") #=> 2
  #     ex.method_to_memoize("b") #=> 2
  ##
  def memo_wise(method_name_or_hash)
    if Hash === method_name_or_hash
      unless method_name_or_hash.keys == [:self]
        raise ArgumentError, "`:self` is the only key allowed in memo_wise"
      end

      method_name = method_name_or_hash[:self]

      # In Ruby, "class methods" are implemented as normal instance methods
      # on the "singleton class" of a given Class object, found via
      # {Class#singleton_class}.
      # See: https://medium.com/@leo_hetsch/demystifying-singleton-classes-in-ruby-caf3fa4c9d91
      #
      # So, we make the singleton class extend the MemoWise module too, and
      # just delegate the call to the `memo_wise` method that is now defined
      # on the singleton class.
      singleton_class.extend(MemoWise)
      return singleton_class.memo_wise(method_name)
    end

    method_name = method_name_or_hash

    raise ArgumentError, "#{method_name.inspect} must be a Symbol" unless method_name.is_a?(Symbol)

    api = MemoWise::InternalAPI.new(self)
    visibility = api.method_visibility(method_name)
    method = instance_method(method_name)

    case MemoWise::InternalAPI.method_arguments(method)
    when MemoWise::InternalAPI::NONE
      # Zero-arg methods can use simpler/more performant logic because the
      # hash key is just the method name.
      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}
          _memo_wise_output = @_memo_wise[:#{method_name}]
          if _memo_wise_output || @_memo_wise.key?(:#{method_name})
            _memo_wise_output
          else
            @_memo_wise[:#{method_name}] = super(&nil)
          end
        HEREDOC
    when MemoWise::InternalAPI::ONE_REQUIRED_POSITIONAL, MemoWise::InternalAPI::ONE_REQUIRED_KEYWORD
      key = method.parameters.first.last
      index = api.index(method_name)

      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}(#{MemoWise::InternalAPI.args_str(method)})
          _memo_wise_hash = (@_memo_wise[:#{method_name}] ||= {})
          _memo_wise_output = _memo_wise_hash[#{key}]
          if _memo_wise_output || _memo_wise_hash.key?(#{key})
            _memo_wise_output
          else
            _memo_wise_hash[#{key}] = #{original_memo_wised_name}(#{MemoWise::InternalAPI.call_str(method)})
          end
        end
      HEREDOC
      # MemoWise::InternalAPI::MULTIPLE_REQUIRED, MemoWise::InternalAPI::SPLAT,
      # MemoWise::InternalAPI::DOUBLE_SPLAT, MemoWise::InternalAPI::SPLAT_AND_DOUBLE_SPLAT
    else
      # NOTE: When benchmarking this implementation against something like:
      #
      #   @_memo_wise.fetch(key) do
      #     ...
      #   end
      #
      # this implementation may sometimes perform worse than the above. This
      # is because this case uses a more complex hash key (see
      # `MemoWise::InternalAPI.key_str`), and hashing that key has less
      # consistent performance. In general, this should still be faster for
      # truthy results because `Hash#[]` generally performs hash lookups
      # faster than `Hash#fetch`.
      index = api.index(method_name)
      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}(#{MemoWise::InternalAPI.args_str(method)})
          _memo_wise_hash = (@_memo_wise[:#{method_name}] ||= {})
          _memo_wise_key = #{MemoWise::InternalAPI.key_str(method)}
          _memo_wise_output = _memo_wise_hash[_memo_wise_key]
          if _memo_wise_output || _memo_wise_hash.key?(_memo_wise_key)
            _memo_wise_output
          else
            _memo_wise_hash[_memo_wise_key] = #{original_memo_wised_name}(#{MemoWise::InternalAPI.call_str(method)})
          end
        end
      HEREDOC
    end

    memo_wise_module.send(visibility, method_name)

    method_name
  end

  # Override [Module#instance_method](https://ruby-doc.org/core-3.0.0/Module.html#method-i-instance_method)
  # to proxy the original `UnboundMethod#parameters` results. We want the
  # parameters to reflect the original method in order to support callers
  # who want to use Ruby reflection to process the method parameters,
  # because our overridden `#initialize` method, and in some cases the
  # generated memoized methods, will have a generic set of parameters
  # (`...` or `*args, **kwargs`), making reflection on method parameters
  # useless without this.
  def instance_method(symbol)
    # Start by calling the original `Module#instance_method` method
    super.tap do |curr_method|
      # At this point, `curr_method` is either a real instance method on this
      # module, or it is MemoWise method defined on the `memo_wise_module`.
      # We check if it is the latter, by looking at the owner of the method and
      # checking to see if it has a super method defined (which should be the case
      # for all MemoWised methods).
      memo_wise_method = curr_method.owner == memo_wise_module && curr_method.super_method

      if memo_wise_method
        # This means, we need to use the `parameters` of the super method of this
        # method, which should be the original MemoWised method.
        orig_method = curr_method.super_method
        orig_params = orig_method.parameters
        curr_method.define_singleton_method(:parameters) { orig_params }
      end
    end
  end

  def memo_wise_module
    @memo_wise_module ||= build_module.tap { |mod| prepend(mod) }
  end

  private

  def build_module
    mod = Module.new do
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
      def _memo_wise
        @_memo_wise ||= []
      end

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
      def _memo_wise_sentinels
        @_memo_wise_sentinels ||= []
      end

      # In order to support memoization on frozen (immutable) objects, we
      # need to override the `Object#freeze` method, initialize our lazy
      # initialized internal state and call the `super` method. This allows
      # the cleanest way to support frozen objects without intercepting the
      # constructor method.
      #
      # For examples of frozen objects, see classes created by the
      # [Values](https://github.com/tcrayford/Values)
      # [gem](https://rubygems.org/gems/values).
      def freeze
        _memo_wise
        _memo_wise_sentinels
        super
      end

      # Presets the memoized result for the given method to the result of the given
      # block.
      #
      # This method is for situations where the caller *already* has the result of
      # an expensive method call, and wants to preset that result as memoized for
      # future calls. In other words, the memoized method will be called *zero*
      # times rather than once.
      #
      # NOTE: Currently, no attempt is made to validate that the given arguments are
      # valid for the given method.
      #
      # @param method_name [Symbol]
      #   Name of a method previously set up with `#memo_wise`.
      #
      # @param args [Array]
      #   (Optional) If the method takes positional args, these are the values of
      #   position args for which the given block's result will be preset as the
      #   memoized result.
      #
      # @param kwargs [Hash]
      #   (Optional) If the method takes keyword args, these are the keys and values
      #   of keyword args for which the given block's result will be preset as the
      #   memoized result.
      #
      # @yieldreturn [Object]
      #   The result of the given block will be preset as memoized for future calls
      #   to the given method.
      #
      # @return [void]
      #
      # @example
      #   class Example
      #     extend MemoWise
      #     attr_reader :method_called_times
      #
      #     def method_to_preset
      #       @method_called_times = (@method_called_times || 0) + 1
      #       "A"
      #     end
      #     memo_wise :method_to_preset
      #   end
      #
      #   ex = Example.new
      #
      #   ex.preset_memo_wise(:method_to_preset) { "B" }
      #
      #   ex.method_to_preset #=> "B"
      #
      #   ex.method_called_times #=> nil
      #
      def preset_memo_wise(method_name, *args, **kwargs)
        raise ArgumentError, "Pass a block as the value to preset for #{method_name}, #{args}" unless block_given?

        api = MemoWise::InternalAPI.new(self)
        method = api.memo_wised_method(method_name)

        method_arguments = MemoWise::InternalAPI.method_arguments(method)
        index = api.index(method_name)

        if method_arguments == MemoWise::InternalAPI::NONE
          _memo_wise_sentinels[index] = true
          _memo_wise[index] = yield
          return
        end

        hash = (_memo_wise[index] ||= {})

        case method_arguments
        when MemoWise::InternalAPI::ONE_REQUIRED_POSITIONAL then hash[args.first] = yield
        when MemoWise::InternalAPI::ONE_REQUIRED_KEYWORD then hash[kwargs.first.last] = yield
        when MemoWise::InternalAPI::SPLAT then hash[args] = yield
        when MemoWise::InternalAPI::DOUBLE_SPLAT then hash[kwargs] = yield
        when MemoWise::InternalAPI::MULTIPLE_REQUIRED
          key = method.parameters.map.with_index do |(type, name), idx|
            type == :req ? args[idx] : kwargs[name]
          end
          hash[key] = yield
        else # MemoWise::InternalAPI::SPLAT_AND_DOUBLE_SPLAT
          hash[[args, kwargs]] = yield
        end
      end

      # Resets memoized results of a given method, or all methods.
      #
      # There are three _reset modes_ depending on how this method is called:
      #
      # **method + args** mode (most specific)
      #
      # - If given `method_name` and *either* `args` *or* `kwargs` *or* both:
      # - Resets *only* the memoized result of calling `method_name` with those
      #   particular arguments.
      #
      # **method** (any args) mode
      #
      # - If given `method_name` and *neither* `args` *nor* `kwargs`:
      # - Resets *all* memoized results of calling `method_name` with any arguments.
      #
      # **all methods** mode (most general)
      #
      # - If *not* given `method_name`:
      # - Resets all memoized results of calling *all methods*.
      #
      # @param method_name [Symbol, nil]
      #   (Optional) Name of a method previously set up with `#memo_wise`. If not
      #   given, will reset *all* memoized results for *all* methods.
      #
      # @param args [Array]
      #   (Optional) If the method takes positional args, these are the values of
      #   position args for which the memoized result will be reset.
      #
      # @param kwargs [Hash]
      #   (Optional) If the method takes keyword args, these are the keys and values
      #   of keyword args for which the memoized result will be reset.
      #
      # @return [void]
      #
      # @example
      #   class Example
      #     extend MemoWise
      #
      #     def method_to_reset(x)
      #       @method_called_times = (@method_called_times || 0) + 1
      #     end
      #     memo_wise :method_to_reset
      #   end
      #
      #   ex = Example.new
      #
      #   ex.method_to_reset("a") #=> 1
      #   ex.method_to_reset("a") #=> 1
      #   ex.method_to_reset("b") #=> 2
      #   ex.method_to_reset("b") #=> 2
      #
      #   ex.reset_memo_wise(:method_to_reset, "a") # reset "method + args" mode
      #
      #   ex.method_to_reset("a") #=> 3
      #   ex.method_to_reset("a") #=> 3
      #   ex.method_to_reset("b") #=> 2
      #   ex.method_to_reset("b") #=> 2
      #
      #   ex.reset_memo_wise(:method_to_reset) # reset "method" (any args) mode
      #
      #   ex.method_to_reset("a") #=> 4
      #   ex.method_to_reset("b") #=> 5
      #
      #   ex.reset_memo_wise # reset "all methods" mode
      #
      def reset_memo_wise(method_name = nil, *args, **kwargs)
        if method_name.nil?
          raise ArgumentError, "Provided args when method_name = nil" unless args.empty?
          raise ArgumentError, "Provided kwargs when method_name = nil" unless kwargs.empty?

          @_memo_wise.clear
          return
        end

        method = method(MemoWise::InternalAPI.original_memo_wised_name(method_name))
        method_arguments = MemoWise::InternalAPI.method_arguments(method)

        # method_name == MemoWise::InternalAPI::NONE will be covered by this case.
        @_memo_wise.delete(method_name) if args.empty? && kwargs.empty?
        method_hash = @_memo_wise[method_name]

        case method_arguments
        when MemoWise::InternalAPI::ONE_REQUIRED_POSITIONAL then method_hash&.delete(args.first)
        when MemoWise::InternalAPI::ONE_REQUIRED_KEYWORD then method_hash&.delete(kwargs.first.last)
        when MemoWise::InternalAPI::SPLAT then method_hash&.delete(args)
        when MemoWise::InternalAPI::DOUBLE_SPLAT then method_hash&.delete(kwargs)
        else # MemoWise::InternalAPI::MULTIPLE_REQUIRED, MemoWise::InternalAPI::SPLAT_AND_DOUBLE_SPLAT
          key = if method_arguments == MemoWise::InternalAPI::SPLAT_AND_DOUBLE_SPLAT
                  [args, kwargs]
                else
                  method.parameters.map.with_index do |(type, name), i|
                    type == :req ? args[i] : kwargs[name]
                  end
                end
          method_hash&.delete(key)
        end
      end
    end

    mod.tap { const_set(:MemoWiseMethods, mod) }
  end
end

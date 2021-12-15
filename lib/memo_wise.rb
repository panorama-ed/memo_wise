# frozen_string_literal: true

require "set"

require "memo_wise/internal_api"
require "memo_wise/module_builder"
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
    if method_name_or_hash.is_a?(Hash)
      raise ArgumentError, "`:self` is the only key allowed in memo_wise" unless method_name_or_hash.keys == [:self]

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

    visibility = MemoWise::InternalAPI.new(self).method_visibility(method_name)
    method = instance_method(method_name)

    case MemoWise::InternalAPI.method_arguments(method)
    when MemoWise::InternalAPI::NONE
      # Zero-arg methods can use simpler/more performant logic because the
      # hash key is just the method name.
      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}
          _memo_wise.fetch(:#{method_name}) do
            # We pass (&nil) here so we don't memoize methods with explicit block arguments
            _memo_wise[:#{method_name}] = super(&nil)
          end
        end
      HEREDOC
    when MemoWise::InternalAPI::ONE_REQUIRED_POSITIONAL, MemoWise::InternalAPI::ONE_REQUIRED_KEYWORD
      key = method.parameters.first.last

      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}(#{MemoWise::InternalAPI.args_str(method)})
          _memo_wise_hash = (_memo_wise[:#{method_name}] ||= {})
          _memo_wise_output = _memo_wise_hash[#{key}]
          if _memo_wise_output || _memo_wise_hash.key?(#{key})
            _memo_wise_output
          else
            _memo_wise_hash[#{key}] = super(#{MemoWise::InternalAPI.call_str(method)})
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
      memo_wise_module.module_eval <<~HEREDOC, __FILE__, __LINE__ + 1
        def #{method_name}(#{MemoWise::InternalAPI.args_str(method)})
          _memo_wise_hash = (_memo_wise[:#{method_name}] ||= {})
          _memo_wise_key = #{MemoWise::InternalAPI.key_str(method)}

          _memo_wise_output = _memo_wise_hash[_memo_wise_key]
          if _memo_wise_output || _memo_wise_hash.key?(_memo_wise_key)
            _memo_wise_output
          else
            _memo_wise_hash[_memo_wise_key] = super(#{MemoWise::InternalAPI.call_str(method)})
          end
        end
      HEREDOC
    end

    memo_wise_module.send(visibility, method_name)

    method_name
  end

  def memo_wise_module
    @memo_wise_module ||= ModuleBuilder.build.tap do |mod|
      prepend(mod)
      const_set(:MemoWiseMethods, mod)
    end
  end

  ##
  # @!method self.preset_memo_wise(method_name, *args, **kwargs)
  #   Implementation of {#preset_memo_wise} for class methods.
  #
  #   @note This method is only defined on a class once at least one class
  #     method on that same class is memoized by calling `memo_wise`.
  #
  #   @example
  #     class Example
  #       extend MemoWise
  #
  #       def self.method_called_times
  #         @method_called_times
  #       end
  #
  #       def self.method_to_preset
  #         @method_called_times = (@method_called_times || 0) + 1
  #         "A"
  #       end
  #       memo_wise self: :method_to_preset
  #     end
  #
  #     Example.preset_memo_wise(:method_to_preset) { "B" }
  #
  #     Example.method_to_preset #=> "B"
  #
  #     Example.method_called_times #=> nil
  ##

  ##
  # @!method self.reset_memo_wise(method_name = nil, *args, **kwargs)
  #   Implementation of {#reset_memo_wise} for class methods.
  #
  #   @note This method is only defined on a class once at least one class
  #     method on that same class is memoized by calling `memo_wise`.
  #
  #   @example
  #     class Example
  #       extend MemoWise
  #
  #       def self.method_to_reset(x)
  #         @method_called_times = (@method_called_times || 0) + 1
  #       end
  #       memo_wise self: :method_to_reset
  #     end
  #
  #     Example.method_to_reset("a") #=> 1
  #     Example.method_to_reset("a") #=> 1
  #     Example.method_to_reset("b") #=> 2
  #     Example.method_to_reset("b") #=> 2
  #
  #     Example.reset_memo_wise(:method_to_reset, "a") # reset "method + args" mode
  #
  #     Example.method_to_reset("a") #=> 3
  #     Example.method_to_reset("a") #=> 3
  #     Example.method_to_reset("b") #=> 2
  #     Example.method_to_reset("b") #=> 2
  #
  #     Example.reset_memo_wise(:method_to_reset) # reset "method" (any args) mode
  #
  #     Example.method_to_reset("a") #=> 4
  #     Example.method_to_reset("b") #=> 5
  #
  #     Example.reset_memo_wise # reset "all methods" mode
  ##

  ##
  # @!method preset_memo_wise(method_name, *args, **kwargs)
  #
  # Presets the memoized result for the given method to the result of the given
  # block.
  #
  # @note This method is only defined on an instance once at least one
  #   instance method on the class is memoized by calling `memo_wise`.
  #
  # This method is for situations where the caller *already* has the result of
  # an expensive method call, and wants to preset that result as memoized for
  # future calls. In other words, the memoized method will be called *zero*
  # times rather than once.
  #
  # @note Currently, no attempt is made to validate that the given arguments are
  #   valid for the given method.
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
  ##

  ##
  # @!method reset_memo_wise(method_name = nil, *args, **kwargs)
  #
  # Resets memoized results of a given method, or all methods.
  #
  # @note This method is only defined on an instance once at least one
  #   instance method on the class is memoized by calling `memo_wise`.
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
  ##

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
end

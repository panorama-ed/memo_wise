# frozen_string_literal: true

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
#   1. Add `prepend MemoWise` to the top of the class or module
#   2. Call {.memo_wise} to implement memoization for a given method
#
# @see .memo_wise
#
module MemoWise # rubocop:disable Metrics/ModuleLength
  # Constructor to setup memoization state before
  # [calling the original](https://medium.com/@jeremy_96642/ruby-method-auditing-using-module-prepend-4f4e69aacd95)
  # constructor.
  #
  # - **Q:** Why is [Module#prepend](https://ruby-doc.org/core-2.7.1/Module.html#method-i-prepend)
  #          important here
  #          ([more info](https://medium.com/@leo_hetsch/ruby-modules-include-vs-prepend-vs-extend-f09837a5b073))?
  # - **A:** To setup *mutable state* inside the instance, even if the original
  #          constructor will then call
  #          [Object#freeze](https://ruby-doc.org/core-2.7.1/Object.html#method-i-freeze).
  #
  # This approach supports memoization on frozen (immutable) objects -- for
  # example, classes created by the
  # [Values](https://github.com/tcrayford/Values)
  # [gem](https://rubygems.org/gems/values).
  #
  def initialize(*)
    @_memo_wise = Hash.new { |h, k| h[k] = {} }
    super
  end

  # @private
  #
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
  #   MemoWise.has_arg?(Example.instance_method(:no_args)) #=> false
  #
  #   MemoWise.has_arg?(Example.instance_method(:position_arg)) #=> true
  #
  def self.has_arg?(method) # rubocop:disable Naming/PredicateName
    method.parameters.any? do |(param, _)|
      param == :req || param == :opt || param == :rest # rubocop:disable Style/MultipleComparison
    end
  end

  # @private
  #
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
  #   MemoWise.has_kwarg?(Example.instance_method(:position_args)) #=> false
  #
  #   MemoWise.has_kwarg?(Example.instance_method(:keyword_args)) #=> true
  #
  def self.has_kwarg?(method) # rubocop:disable Naming/PredicateName
    method.parameters.any? do |(param, _)|
      param == :keyreq || param == :key || param == :keyrest # rubocop:disable Style/MultipleComparison
    end
  end

  # @private
  #
  # Private setup method, called automatically by `prepend MemoWise` in a class.
  #
  # @param target [Class]
  #   The `Class` into to prepend the MemoWise methods e.g. `memo_wise`
  #
  # @see https://ruby-doc.org/core-2.7.1/Module.html#method-i-prepended
  #
  # @example
  #   class Example
  #     prepend MemoWise
  #   end
  #
  def self.prepended(target) # rubocop:disable Metrics/PerceivedComplexity
    class << target
      # NOTE: See YARD docs for {.memo_wise} directly below this method!
      def memo_wise(method_name) # rubocop:disable Metrics/PerceivedComplexity
        unless method_name.is_a?(Symbol)
          raise ArgumentError,
                "#{method_name.inspect} must be a Symbol"
        end

        method_visibility = if private_method_defined?(method_name)
                              :private
                            elsif protected_method_defined?(method_name)
                              :protected
                            else
                              :public
                            end

        original_memo_wised_name = :"_memo_wise_original_#{method_name}"
        alias_method original_memo_wised_name, method_name
        private original_memo_wised_name

        method = instance_method(method_name)

        # Zero-arg methods can use simpler/more performant logic because the
        # hash key is just the method name.
        if method.arity.zero?
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}
              @_memo_wise.fetch(:#{method_name}) do
                @_memo_wise[:#{method_name}] = #{original_memo_wised_name}
              end
            end
          END_OF_METHOD
        else
          # If our method has arguments, we need to separate out our handling of
          # normal args vs. keyword args due to the changes in Ruby 3.
          # See: <link>
          # By only including logic for *args or **kwargs when they are used in
          # the method, we can avoid allocating unnecessary arrays and hashes.
          has_arg = MemoWise.has_arg?(method)

          if has_arg && MemoWise.has_kwarg?(method)
            args_str = "(*args, **kwargs)"
            fetch_key = "[args, kwargs].freeze"
          elsif has_arg
            args_str = "(*args)"
            fetch_key = "args"
          else
            args_str = "(**kwargs)"
            fetch_key = "kwargs"
          end

          # Note that we don't need to freeze args before using it as a hash key
          # because Ruby always copies argument arrays when splatted.
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}#{args_str}
              hash = @_memo_wise[:#{method_name}]
              hash.fetch(#{fetch_key}) do
                hash[#{fetch_key}] = #{original_memo_wised_name}#{args_str}
              end
            end
          END_OF_METHOD
        end

        module_eval <<-END_OF_VISIBILITY, __FILE__, __LINE__ + 1
          "#{method_visibility} :#{method_name}"
        END_OF_VISIBILITY
      end
    end
  end

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
  #   @param method_name [Symbol]
  #     Name of method for which to implement memoization.
  #
  #   @return [void]
  #
  #   @example
  #     class Example
  #       prepend MemoWise
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
  #   Name of a method previously setup with `#memo_wise`.
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
  #     prepend MemoWise
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
    validate_memo_wised!(method_name)

    unless block_given?
      raise ArgumentError,
            "Pass a block as the value to preset for #{method_name}, #{args}"
    end

    validate_params!(method_name, args)

    if method(method_name).arity.zero?
      @_memo_wise[method_name] = yield
    else
      @_memo_wise[method_name][fetch_key(method_name, *args, **kwargs)] = yield
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
  #   (Optional) Name of a method previously setup with `#memo_wise`. If not
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
  #     prepend MemoWise
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
  #
  #   ex.method_to_reset("b") #=> 2
  #   ex.method_to_reset("b") #=> 2
  #
  #   ex.reset_memo_wise(:method_to_reset, "a") # reset "method + args" mode
  #
  #   ex.method_to_reset("a") #=> 3
  #   ex.method_to_reset("a") #=> 3
  #
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
      unless args.empty?
        raise ArgumentError, "Provided args when method_name = nil"
      end

      unless kwargs.empty?
        raise ArgumentError, "Provided kwargs when method_name = nil"
      end

      return @_memo_wise.clear
    end

    unless method_name.is_a?(Symbol)
      raise ArgumentError, "#{method_name.inspect} must be a Symbol"
    end

    unless respond_to?(method_name)
      raise ArgumentError, "#{method_name} is not a defined method"
    end

    validate_memo_wised!(method_name)

    if args.empty? && kwargs.empty?
      @_memo_wise.delete(method_name)
    else
      @_memo_wise[method_name].delete(fetch_key(method_name, *args, **kwargs))
    end
  end

  private

  def validate_memo_wised!(method_name)
    original_memo_wised_name = :"_memo_wise_original_#{method_name}"

    unless self.class.private_method_defined?(original_memo_wised_name)
      raise ArgumentError, "#{method_name} is not a memo_wised method"
    end
  end

  def fetch_key(method_name, *args, **kwargs)
    method = self.class.instance_method(method_name)
    has_arg = MemoWise.has_arg?(method)

    if has_arg && MemoWise.has_kwarg?(method)
      [args, kwargs].freeze
    elsif has_arg
      args
    else
      kwargs
    end
  end

  # TODO: Parameter validation for presetting values
  def validate_params!(method_name, args); end
end

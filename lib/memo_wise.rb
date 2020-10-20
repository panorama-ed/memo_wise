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
# **See Also:**
#
#   - {.memo_wise} for API and usage examples.
#   - {file:README.md} for general project information.
#
module MemoWise # rubocop:disable Metrics/ModuleLength
  # Constructor to setup memoization state before
  # [calling the original](https://medium.com/@jeremy_96642/ruby-method-auditing-using-module-prepend-4f4e69aacd95)
  # constructor.
  #
  # - **Q:** Why is [Module#prepend](https://ruby-doc.org/core-2.7.2/Module.html#method-i-prepend)
  #          important here
  #          ([more info](https://medium.com/@leo_hetsch/ruby-modules-include-vs-prepend-vs-extend-f09837a5b073))?
  # - **A:** To setup *mutable state* inside the instance, even if the original
  #          constructor will then call
  #          [Object#freeze](https://ruby-doc.org/core-2.7.2/Object.html#method-i-freeze).
  #
  # This approach supports memoization on frozen (immutable) objects -- for
  # example, classes created by the
  # [Values](https://github.com/tcrayford/Values)
  # [gem](https://rubygems.org/gems/values).
  #
  def initialize(*)
    MemoWise.create_memo_wise_state!(self)
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
  # Determine whether `method` takes a *block* arg.
  #
  # There is one type of block arg:
  #
  #   * *Block* -- ex: `def foo(&block)`
  #
  # @param method [Method, UnboundMethod]
  #   Arguments of this method will be checked
  #
  # @return [Boolean]
  #   Return `true` if `method` accepts a block argument
  #
  # @example
  #   class Example
  #     def position_args(a, b=1)
  #     end
  #
  #     def block_args(&block)
  #       block.call
  #     end
  #   end
  #
  #   MemoWise.has_block_arg?(Example.instance_method(:position_args)) #=> false
  #
  #   MemoWise.has_block_arg?(Example.instance_method(:block_args)) #=> true
  #
  def self.has_block_arg?(method) # rubocop:disable Naming/PredicateName
    method.parameters.last&.first == :block
  end

  # @private
  #
  # Returns scope, visibility, class, and method object for a given method name.
  #
  # @param klass [Class]
  #   Class in which to search for a method by name.
  #
  # @param method_name [Symbol]
  #   Name of method to search for at both class and instance levels.
  #
  # @return [(Symbol, Symbol, Class, UnboundMethod)]
  #   Return **scope**, **visibility**, **class**, and **method** corresponding
  #   to the given method name on the target class.
  #
  #     - **scope**      -- either `:class` or `:instance`
  #     - **visibility** -- either `:private`, `:protected`, or `:public`
  #     - **class**      -- either `klass` or its
  #                         [singleton class](https://medium.com/@leo_hetsch/demystifying-singleton-classes-in-ruby-caf3fa4c9d91)
  #     - **method**     -- instance of {UnboundMethod}
  #
  # @raise ArgumentError
  #   Raises `ArgumentError` unless `method_name` is a `Symbol` corresponding
  #   to a class or instance method defined on `klass`.
  #
  # rubocop:disable Layout/LineLength
  # @example
  #   class Example
  #     def an_instance_method; end
  #
  #     class << self
  #       def a_class_method; end
  #       private :a_class_method
  #     end
  #   end
  #
  #   MemoWise.method_info(Example, :an_instance_method)[0, 2] #=> [:instance, :public]
  #
  #   MemoWise.method_info(Example, :a_class_method)[0, 2] #=> [:class, :private]
  # rubocop:enable Layout/LineLength
  #
  def self.method_info(klass, method_name)
    unless klass.is_a?(Class) || klass.is_a?(Module)
      raise ArgumentError, "#{klass.inspect} must be a Class or Module"
    end

    unless method_name.is_a?(Symbol)
      raise ArgumentError, "#{method_name.inspect} must be a Symbol"
    end

    # In Ruby, "class methods" are implemented as normal instance methods
    # on the "singleton class" of a given Class object, found via
    # {Class#singleton_class}.
    # See: https://medium.com/@leo_hetsch/demystifying-singleton-classes-in-ruby-caf3fa4c9d91
    singleton = klass.singleton_class

    is_singleton_method =
      singleton.private_instance_methods.include?(method_name) ||
      singleton.instance_methods.include?(method_name)

    if is_singleton_method
      visibility = method_visibility(singleton, method_name)
      [:class, visibility, singleton, singleton.instance_method(method_name)]
    else
      visibility = method_visibility(klass, method_name)
      [:instance, visibility, klass, klass.instance_method(method_name)]
    end
  end

  # @private
  #
  # Returns visibility of an instance method defined on a class.
  #
  # @param klass [Class]
  #   Class in which to find the visibility of an existing *instance* method.
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
  def self.method_visibility(klass, method_name)
    if klass.private_method_defined?(method_name)
      :private
    elsif klass.protected_method_defined?(method_name)
      :protected
    elsif klass.public_method_defined?(method_name)
      :public
    else
      raise ArgumentError, "#{method_name.inspect} must be a method on #{klass}"
    end
  end

  # @private
  #
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

    # Option 1: Derive from `#to_s` of the singleton class
    #   * Works unless original class NOT assigned to constant
    #   * Depends on an undocumented naming convention in Ruby, where singleton
    #     class of `Foo` will return "#<Class:Foo>" from `#to_s` method.
    name = klass.to_s.match(/#<Class:([^>]+)>/)&.[](1)
    raise NameError if name.nil?

    Object.const_get(name) # raises NameError if not found
  rescue NameError
    # Option 2: Search ObjectSpace
    #   * Works in all cases, so makes a good fallback option
    #   * 1:1 relationship of singleton class to original class is documented
    #   * Even though this only runs at load time, searches all Class objects
    ObjectSpace.each_object(Class).find do |cls|
      !cls.singleton_class? && cls.singleton_class == klass
    end
  end

  # @private
  #
  # Create initial mutable state to store memoized values.
  #
  # @param [Object] obj
  #   Object in which to create mutable state to store future memoized values
  #
  # @raise ArgumentError
  #   Raises `ArgumentError` if the state variable already exists on `obj`.
  #
  def self.create_memo_wise_state!(obj)
    if obj.instance_variables.include?(:@_memo_wise)
      raise ArgumentError, "MemoWise state already created: #{obj.inspect}"
    end

    obj.instance_variable_set(
      :@_memo_wise,
      Hash.new { |h, k| h[k] = {} }
    )
  end

  # @private
  #
  # Private setup method, called automatically by `prepend MemoWise` in a class.
  #
  # @param target [Class]
  #   The `Class` into to prepend the MemoWise methods e.g. `memo_wise`
  #
  # @see https://ruby-doc.org/core-2.7.2/Module.html#method-i-prepended
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
        scope, visibility, klass, method =
          MemoWise.method_info(self, method_name)

        original_memo_wised_name = :"_memo_wise_original_#{method_name}"
        klass.send(:alias_method, original_memo_wised_name, method_name)
        klass.send(:private, original_memo_wised_name)

        if scope == :class
          MemoWise.create_memo_wise_state!(self)
        elsif scope == :instance && klass.singleton_class?
          original_class = MemoWise.original_class_from_singleton(klass)
          MemoWise.create_memo_wise_state!(original_class)
        end

        if MemoWise.has_block_arg?(method)
          raise ArgumentError,
                "Methods which take block arguments cannot be memoized"
        end

        # Zero-arg methods can use simpler/more performant logic because the
        # hash key is just the method name.
        if method.arity.zero?
          klass.module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
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
          klass.module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}#{args_str}
              hash = @_memo_wise[:#{method_name}]
              hash.fetch(#{fetch_key}) do
                hash[#{fetch_key}] = #{original_memo_wised_name}#{args_str}
              end
            end
          END_OF_METHOD
        end

        klass.send(visibility, method_name)
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

  # Validates that {.memo_wise} has already been called on `method_name`.
  def validate_memo_wised!(method_name)
    original_memo_wised_name = :"_memo_wise_original_#{method_name}"

    unless self.class.private_method_defined?(original_memo_wised_name)
      raise ArgumentError, "#{method_name} is not a memo_wised method"
    end
  end

  # Returns arguments key to lookup memoized results for given `method_name`.
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

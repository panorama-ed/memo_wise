# frozen_string_literal: true

require "memo_wise/version"

module MemoWise
  def initialize(*values)
    @_memo_wise = Hash.new { |h, k| h[k] = {} }
    super
  end

  def self.has_arg?(method) # rubocop:disable Naming/PredicateName
    method.parameters.any? do |(param, _)|
      param == :req || param == :opt || param == :rest # rubocop:disable Style/MultipleComparison
    end
  end

  def self.has_kwarg?(method) # rubocop:disable Naming/PredicateName
    method.parameters.any? do |(param, _)|
      param == :keyreq || param == :key || param == :keyrest # rubocop:disable Style/MultipleComparison
    end
  end

  def self.prepended(target) # rubocop:disable Metrics/PerceivedComplexity
    class << target
      # Implements memoization for the given method name.
      #
      # @param method_name [Symbol]
      #   Name of method for which to implement memoization.
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

        not_memoized_name = :"_not_memoized_#{method_name}"
        alias_method not_memoized_name, method_name
        private not_memoized_name

        method = instance_method(method_name)

        # Zero-arg methods can use simpler/more performant logic because the
        # hash key is just the method name.
        if method.arity.zero?
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}
              @_memo_wise.fetch(:#{method_name}) do
                @_memo_wise[:#{method_name}] = #{not_memoized_name}
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
                hash[#{fetch_key}] = #{not_memoized_name}#{args_str}
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

  def reset_memo_wise(method_name, *args, **kwargs)
    unless method_name.is_a?(Symbol)
      raise ArgumentError, "#{method_name.inspect} must be a Symbol"
    end

    unless respond_to?(method_name)
      raise ArgumentError, "#{method_name} is not a defined method"
    end

    if args.empty? && kwargs.empty?
      @_memo_wise.delete(method_name)
    else
      method = self.class.instance_method(method_name)

      has_arg = MemoWise.has_arg?(method)

      if has_arg && MemoWise.has_kwarg?(method)
        @_memo_wise[method_name].delete([args, kwargs])
      elsif has_arg
        @_memo_wise[method_name].delete(args)
      else
        @_memo_wise[method_name].delete(kwargs)
      end
    end
  end

  def reset_all_memo_wise
    @_memo_wise.clear
  end
end

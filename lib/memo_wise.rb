# frozen_string_literal: true

require "memo_wise/version"

module MemoWise
  def initialize(*values)
    @_memo_wise = Hash.new { |h, k| h[k] = {} }
    super
  end

  def self.prepended(target)
    class << target
      # Implements memoization for the given method name.
      #
      # @param method_name [Symbol]
      #   Name of method for which to implement memoization.
      def memo_wise(method_name)
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

        if instance_method(method_name).arity.zero?
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}
              @_memo_wise.fetch(:#{method_name}) do
                @_memo_wise[:#{method_name}] = #{not_memoized_name}
              end
            end
          END_OF_METHOD
        else
          # Note that we don't need to freeze args before using it as a hash key
          # because Ruby always copies argument arrays when splatted.
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}(*args)
              hash = @_memo_wise[:#{method_name}]
              hash.fetch(args) do
                hash[args] = #{not_memoized_name}(*args)
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

  def reset_memo_wise(method_name, *args)
    unless method_name.is_a?(Symbol)
      raise ArgumentError, "#{method_name.inspect} must be a Symbol"
    end

    unless respond_to?(method_name)
      raise ArgumentError, "#{method_name} is not a defined method"
    end

    if args.empty?
      @_memo_wise.delete(method_name)
    else
      @_memo_wise[method_name].delete(args)
    end
  end

  def reset_all_memo_wise
    @_memo_wise.clear
  end
end

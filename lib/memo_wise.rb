# frozen_string_literal: true

require "memo_wise/version"

module MemoWise
  def initialize(*values)
    @_memo_wise = {}
    @_memo_wise_keys = Hash.new { |h, k| h[k] = [] }
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

        module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
          def #{method_name}(*args)
            key = [:#{method_name}, args].freeze
            @_memo_wise.fetch(key) do
              @_memo_wise_keys[:#{method_name}] << args
              @_memo_wise[key] = #{not_memoized_name}(*args)
            end
          end

          #{method_visibility} :#{method_name}
        END_OF_METHOD
      end
    end
  end

  def reset_memo_wise(method_name)
    unless respond_to?(method_name)
      raise ArgumentError, "#{method_name.inspect} is not a defined method"
    end

    @_memo_wise_keys[method_name].each do |args|
      @_memo_wise.delete([method_name, args])
    end

    @_memo_wise_keys.delete(method_name)
  end
end

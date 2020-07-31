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

        original_memo_wised_name = :"_memo_wise_original_#{method_name}"
        alias_method original_memo_wised_name, method_name
        private original_memo_wised_name

        if instance_method(method_name).arity.zero?
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}
              @_memo_wise.fetch(:#{method_name}) do
                @_memo_wise[:#{method_name}] = #{original_memo_wised_name}
              end
            end
          END_OF_METHOD
        else
          module_eval <<-END_OF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}(*args)
              key = [:#{method_name}, args].freeze
              @_memo_wise.fetch(key) do
                @_memo_wise_keys[:#{method_name}] << args
                @_memo_wise[key] = #{original_memo_wised_name}(*args)
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

  def reset_memo_wise(method_name)
    unless method_name.is_a?(Symbol)
      raise ArgumentError, "#{method_name.inspect} must be a Symbol"
    end

    unless respond_to?(method_name)
      raise ArgumentError, "#{method_name} is not a defined method"
    end

    @_memo_wise_keys[method_name].each do |args|
      @_memo_wise.delete([method_name, args])
    end

    @_memo_wise.delete(method_name)
    @_memo_wise_keys.delete(method_name)
  end

  def reset_all_memo_wise
    @_memo_wise_keys.clear
    @_memo_wise.clear
  end

  def preset_memo_wise(method_name, *args, &block)
    original_memo_wised_name = :"_memo_wise_original_#{method_name}"
    unless self.class.private_method_defined?(original_memo_wised_name)
      raise ArgumentError, "#{method_name} is not a memo_wised method"
    end

    unless block
      raise ArgumentError,
            "Pass a block as the value to preset for #{method_name}, #{args}"
    end

    validate_params!(original_memo_wised_name, args)

    @_memo_wise_keys[method_name] << args
    key = if method(method_name).arity.zero?
            method_name
          else
            [method_name, args].freeze
          end

    @_memo_wise[key] = block_given? ? yield : nil
  end

  private

  # TODO: Parameter validation for presetting values
  def validate_params!(method_name, args); end
end

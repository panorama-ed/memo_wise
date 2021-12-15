# frozen_string_literal: true

module ModuleBuilder
  def self.build
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
        @_memo_wise ||= {}
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
        super
      end

      def preset_memo_wise(method_name, *args, **kwargs)
        raise ArgumentError, "#{method_name.inspect} must be a Symbol" unless method_name.is_a?(Symbol)
        raise ArgumentError, "Pass a block as the value to preset for #{method_name}, #{args}" unless block_given?

        api = MemoWise::InternalAPI.new(self)
        method = api.memo_wised_method(method_name)

        method_arguments = MemoWise::InternalAPI.method_arguments(method)

        if method_arguments == MemoWise::InternalAPI::NONE
          _memo_wise[method_name] = yield
          return
        end

        hash = (_memo_wise[method_name] ||= {})

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

      def reset_memo_wise(method_name = nil, *args, **kwargs)
        if method_name.nil?
          raise ArgumentError, "Provided args when method_name = nil" unless args.empty?
          raise ArgumentError, "Provided kwargs when method_name = nil" unless kwargs.empty?

          _memo_wise.clear
          return
        end

        raise ArgumentError, "#{method_name.inspect} must be a Symbol" unless method_name.is_a?(Symbol)
        raise ArgumentError, "#{method_name} is not a defined method" unless respond_to?(method_name, true)

        method = MemoWise::InternalAPI.new(self).memo_wised_method(method_name)

        # method_name == MemoWise::InternalAPI::NONE will be covered by this case.
        _memo_wise.delete(method_name) if args.empty? && kwargs.empty?
        method_hash = _memo_wise[method_name]

        method_arguments = MemoWise::InternalAPI.method_arguments(method)

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
  end
end

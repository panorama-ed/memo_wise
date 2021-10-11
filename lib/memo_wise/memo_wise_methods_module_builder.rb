# frozen_string_literal: true

module MemoWiseMethodsModuleBuilder
  def self.build
    Module.new do
      def _memo_wise
        @_memo_wise ||= {}
      end

      def _memo_wise_hashes
        @_memo_wise_hashes ||= {}
      end

      def freeze
        _memo_wise
        _memo_wise_hashes
        super
      end

      def preset_memo_wise(method_name, *args, **kwargs)
        raise ArgumentError, "Pass a block as the value to preset for #{method_name}, #{args}" unless block_given?

        api = MemoWise::InternalAPI.new(self)
        api.validate_memo_wised!(method_name)

        method = method(method_name)
        if method.arity.zero?
          _memo_wise[method_name] = yield
        else
          key = api.fetch_key(method, *args, **kwargs)
          if api.use_hashed_key?(method)
            hashes = _memo_wise_hashes[method_name] ||= []
            hashes << key
            _memo_wise[key] = yield
          else
            hash = _memo_wise[method_name] ||= {}
            hash[key] = yield
          end
        end
      end

      def reset_memo_wise(method_name = nil, *args, **kwargs)
        if method_name.nil?
          raise ArgumentError, "Provided args when method_name = nil" unless args.empty?
          raise ArgumentError, "Provided kwargs when method_name = nil" unless kwargs.empty?

          _memo_wise.clear
          _memo_wise_hashes.clear
          return
        end

        raise ArgumentError, "#{method_name.inspect} must be a Symbol" unless method_name.is_a?(Symbol)
        raise ArgumentError, "#{method_name} is not a defined method" unless respond_to?(method_name, true)

        api = MemoWise::InternalAPI.new(self)
        api.validate_memo_wised!(method_name)

        method = method(method_name)

        if args.empty? && kwargs.empty?
          _memo_wise.delete(method_name)
          _memo_wise_hashes[method_name]&.each do |hash|
            _memo_wise.delete(hash)
          end
          _memo_wise_hashes.delete(method_name)
        else
          key = api.fetch_key(method, *args, **kwargs)
          if api.use_hashed_key?(method)
            _memo_wise_hashes[method_name]&.delete(key)
            _memo_wise.delete(key)
          else
            _memo_wise[method_name]&.delete(key)
          end
        end
      end
    end
  end
end

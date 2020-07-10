# frozen_string_literal: true

RSpec.describe MemoWise do
  let(:class_with_memo) do
    Class.new do
      prepend MemoWise

      def initialize
        @no_args_counter = 0
        @with_positional_args_counter = 0
        @with_keyword_args_counter = 0
        @special_chars_counter = 0
        @false_method_counter = 0
        @nil_method_counter = 0
        @private_memowise_method_counter = 0
        @protected_memowise_method_counter = 0
        @public_memowise_method_counter = 0
      end

      attr_reader :no_args_counter,
                  :with_positional_args_counter,
                  :with_keyword_args_counter,
                  :special_chars_counter,
                  :false_method_counter,
                  :nil_method_counter,
                  :private_memowise_method_counter,
                  :protected_memowise_method_counter,
                  :public_memowise_method_counter

      def no_args
        @no_args_counter += 1
        "no_args"
      end
      memo_wise :no_args

      def with_positional_args(a, b) # rubocop:disable Naming/MethodParameterName
        @with_positional_args_counter += 1
        "with_positional_args: a=#{a}, b=#{b}"
      end
      memo_wise :with_positional_args

      def with_keyword_args(a:, b:) # rubocop:disable Naming/MethodParameterName
        @with_keyword_args_counter += 1
        "with_keyword_args: a=#{a}, b=#{b}"
      end
      memo_wise :with_keyword_args

      def special_chars?
        @special_chars_counter += 1
        "special_chars?"
      end
      memo_wise :special_chars?

      def false_method
        @false_method_counter += 1
        false
      end
      memo_wise :false_method

      def nil_method
        @nil_method_counter += 1
        nil
      end
      memo_wise :nil_method

      def private_memowise_method
        @private_memowise_method_counter += 1
        "private_memowise_method"
      end
      memo_wise :private_memowise_method
      private :private_memowise_method

      def protected_memowise_method
        @protected_memowise_method_counter += 1
        "protected_memowise_method"
      end
      memo_wise :protected_memowise_method
      protected :protected_memowise_method

      def public_memowise_method
        @public_memowise_method_counter += 1
        "public_memowise_method"
      end
      memo_wise :public_memowise_method
      public :public_memowise_method
    end
  end

  let(:instance) { class_with_memo.new }

  describe "#memo_wise" do
    it "memoizes methods with no arguments" do
      expect(Array.new(4) { instance.no_args }).to all eq("no_args")
      expect(instance.no_args_counter).to eq(1)
    end

    it "memoizes methods with positional arguments" do
      expect(Array.new(4) { instance.with_positional_args(1, 2) }).
        to all eq("with_positional_args: a=1, b=2")

      expect(Array.new(4) { instance.with_positional_args(1, 3) }).
        to all eq("with_positional_args: a=1, b=3")

      # This should be executed once for each set of arguments passed
      expect(instance.with_positional_args_counter).to eq(2)
    end

    it "memoizes methods with keyword arguments" do
      expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
        to all eq("with_keyword_args: a=1, b=2")

      expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
        to all eq("with_keyword_args: a=2, b=3")

      # This should be executed once for each set of arguments passed
      expect(instance.with_keyword_args_counter).to eq(2)
    end

    it "memoizes methods with special characters in the name" do
      expect(Array.new(4) { instance.special_chars? }).
        to all eq("special_chars?")
      expect(instance.special_chars_counter).to eq(1)
    end

    it "memoizes methods with false values" do
      expect(Array.new(4) { instance.false_method }).to all eq(false)
      expect(instance.false_method_counter).to eq(1)
    end

    it "memoizes methods with nil values" do
      expect(Array.new(4) { instance.nil_method }).to all eq(nil)
      expect(instance.nil_method_counter).to eq(1)
    end

    it "does not memoize methods across instances" do
      instance2 = class_with_memo.new

      instance.no_args
      instance2.no_args

      expect(instance.no_args_counter).to eq(1)
      expect(instance2.no_args_counter).to eq(1)
    end

    it "keeps private methods private" do
      expect(instance.private_methods.include?(:private_memowise_method)).
        to eq(true)
    end

    it "keeps public methods public" do
      expect(instance.public_methods.include?(:public_memowise_method)).
        to eq(true)
    end

    it "keeps protected methods protected" do
      expect(instance.protected_methods.include?(:protected_memowise_method)).
        to eq(true)
    end

    context "when the name of the method to memoize is not a symbol" do
      let(:class_with_memo) do
        super().tap { |klass| klass.memo_wise "no_args" }
      end

      it { expect { instance }.to raise_error(ArgumentError) }
    end
  end
end

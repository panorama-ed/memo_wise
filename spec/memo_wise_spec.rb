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
        @true_method_counter = 0
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
                  :true_method_counter,
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

      def true_method
        @true_method_counter += 1
        true
      end
      memo_wise :true_method

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

      def unmemoized_method
        "unmemoized"
      end
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

      expect(instance.no_args_counter).to eq(1)
      expect(instance2.no_args_counter).to eq(0)
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

  describe "#reset_memo_wise" do
    it "resets memoization for methods with no arguments" do
      instance.no_args
      instance.reset_memo_wise(:no_args)
      expect(Array.new(4) { instance.no_args }).to all eq("no_args")
      expect(instance.no_args_counter).to eq(2)
    end

    it "resets memoization for methods with positional arguments" do
      instance.with_positional_args(1, 2)
      instance.with_positional_args(2, 3)
      instance.reset_memo_wise(:with_positional_args)

      expect(Array.new(4) { instance.with_positional_args(1, 2) }).
        to all eq("with_positional_args: a=1, b=2")

      expect(Array.new(4) { instance.with_positional_args(1, 3) }).
        to all eq("with_positional_args: a=1, b=3")

      # This should be executed twice for each set of arguments passed
      expect(instance.with_positional_args_counter).to eq(4)
    end

    it "resets memoization for methods with keyword arguments" do
      instance.with_keyword_args(a: 1, b: 2)
      instance.with_keyword_args(a: 2, b: 3)
      instance.reset_memo_wise(:with_keyword_args)

      expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
        to all eq("with_keyword_args: a=1, b=2")

      expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
        to all eq("with_keyword_args: a=2, b=3")

      # This should be executed twice for each set of arguments passed
      expect(instance.with_keyword_args_counter).to eq(4)
    end

    it "resets memoization for methods with special characters in the name" do
      instance.special_chars?
      instance.reset_memo_wise(:special_chars?)
      expect(Array.new(4) { instance.special_chars? }).
        to all eq("special_chars?")
      expect(instance.special_chars_counter).to eq(2)
    end

    it "resets memoization for methods set to false values" do
      instance.false_method
      instance.reset_memo_wise(:false_method)
      expect(Array.new(4) { instance.false_method }).to all eq(false)
      expect(instance.false_method_counter).to eq(2)
    end

    it "resets memoization for methods with nil values" do
      instance.nil_method
      instance.reset_memo_wise(:nil_method)
      expect(Array.new(4) { instance.nil_method }).to all eq(nil)
      expect(instance.nil_method_counter).to eq(2)
    end

    it "does not reset memoization methods across instances" do
      instance2 = class_with_memo.new

      instance.no_args
      instance2.no_args

      instance.reset_memo_wise(:no_args)

      instance.no_args
      instance2.no_args

      expect(instance.no_args_counter).to eq(2)
      expect(instance2.no_args_counter).to eq(1)
    end

    context "when the name of the method is not a symbol" do
      it {
        expect { instance.reset_memo_wise("no_args") }.
          to raise_error(ArgumentError)
      }
    end

    context "when the method to reset memoization for is not defined" do
      it {
        expect { instance.reset_memo_wise(:not_defined) }.
          to raise_error(ArgumentError)
      }
    end
  end

  describe "#reset_all_memo_wise" do
    let!(:instance) do
      class_with_memo.new.tap do |instance|
        instance.no_args
        instance.with_positional_args(1, 2)
        instance.with_positional_args(2, 3)
        instance.with_keyword_args(a: 1, b: 2)
        instance.with_keyword_args(a: 2, b: 3)
        instance.special_chars?
        instance.false_method
        instance.nil_method

        instance.reset_all_memo_wise
      end
    end

    it "resets memoization for methods with no arguments" do
      expect(Array.new(4) { instance.no_args }).to all eq("no_args")
      expect(instance.no_args_counter).to eq(2)
    end

    it "resets memoization for methods with positional arguments" do
      expect(Array.new(4) { instance.with_positional_args(1, 2) }).
        to all eq("with_positional_args: a=1, b=2")

      expect(Array.new(4) { instance.with_positional_args(1, 3) }).
        to all eq("with_positional_args: a=1, b=3")

      # This should be executed twice for each set of arguments passed
      expect(instance.with_positional_args_counter).to eq(4)
    end

    it "resets memoization for methods with keyword arguments" do
      expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
        to all eq("with_keyword_args: a=1, b=2")

      expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
        to all eq("with_keyword_args: a=2, b=3")

      # This should be executed twice for each set of arguments passed
      expect(instance.with_keyword_args_counter).to eq(4)
    end

    it "resets memoization for methods with special characters in the name" do
      expect(Array.new(4) { instance.special_chars? }).
        to all eq("special_chars?")
      expect(instance.special_chars_counter).to eq(2)
    end

    it "resets memoization for methods with false values" do
      expect(Array.new(4) { instance.false_method }).to all eq(false)
      expect(instance.false_method_counter).to eq(2)
    end

    it "resets memoization for methods with nil values" do
      expect(Array.new(4) { instance.nil_method }).to all eq(nil)
      expect(instance.nil_method_counter).to eq(2)
    end

    it "does not reset memoization methods across instances" do
      instance2 = class_with_memo.new

      instance.no_args
      instance2.no_args

      instance.reset_all_memo_wise

      instance.no_args
      instance2.no_args

      expect(instance.no_args_counter).to eq(3)
      expect(instance2.no_args_counter).to eq(1)
    end
  end

  describe "#preset_memo_wise" do
    shared_examples "presets memoization" do |overriding:|
      let(:expected_counter) { overriding ? 1 : 0 }

      context "with no args" do
        before(:each) { instance.no_args if overriding }

        it "presets memoization" do
          instance.preset_memo_wise(:no_args) { "preset_no_args" }

          expect(Array.new(4) { instance.no_args }).to all eq("preset_no_args")
          expect(instance.no_args_counter).to eq(expected_counter)
        end
      end

      context "with positional args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            instance.with_positional_args(1, 2)
            instance.with_positional_args(3, 4)
          end
        end

        it "presets memoization" do
          instance.preset_memo_wise(:with_positional_args, 1, 2) { "preset_1" }
          instance.preset_memo_wise(:with_positional_args, 3, 4) { "preset_3" }

          expect(Array.new(4) { instance.with_positional_args(1, 2) }).
            to all eq("preset_1")

          expect(Array.new(4) { instance.with_positional_args(3, 4) }).
            to all eq("preset_3")

          expect(instance.with_positional_args_counter).to eq(expected_counter)
        end
      end

      context "with keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            instance.with_keyword_args(a: 1, b: 2)
            instance.with_keyword_args(a: 2, b: 3)
          end
        end

        it "presets memoization" do
          instance.preset_memo_wise(:with_keyword_args, a: 1, b: 2) { "first" }
          instance.preset_memo_wise(:with_keyword_args, a: 2, b: 3) { "second" }

          expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
            to all eq("first")

          expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
            to all eq("second")

          expect(instance.with_keyword_args_counter).to eq(expected_counter)
        end
      end

      context "with special chars" do
        before(:each) { instance.special_chars? if overriding }

        it "presets memoization" do
          instance.preset_memo_wise(:special_chars?) { "preset_special_chars?" }
          expect(Array.new(4) { instance.special_chars? }).
            to all eq("preset_special_chars?")
          expect(instance.special_chars_counter).to eq(expected_counter)
        end
      end

      context "with methods set to false values" do
        before(:each) { instance.true_method if overriding }

        it "presets memoization" do
          instance.preset_memo_wise(:true_method) { false }
          expect(Array.new(4) { instance.true_method }).to all eq(false)
          expect(instance.true_method_counter).to eq(expected_counter)
        end
      end

      context "with methods set to nil values" do
        before(:each) { instance.no_args if overriding }

        it "presets memoization" do
          instance.preset_memo_wise(:no_args) { nil }
          expect(Array.new(4) { instance.no_args }).to all eq(nil)
          expect(instance.no_args_counter).to eq(expected_counter)
        end
      end
    end

    it_behaves_like "presets memoization", overriding: false
    it_behaves_like "presets memoization", overriding: true

    it "does not preset memoization methods across instances" do
      instance2 = class_with_memo.new

      instance.preset_memo_wise(:no_args) { "preset_no_args" }

      expect(instance2.no_args).to eq("no_args")
      expect(instance2.no_args_counter).to eq(1)
    end

    context "when the method to preset memoization for is not memoized" do
      it {
        expect { instance.preset_memo_wise(:unmemoized_method) { nil } }.
          to raise_error(ArgumentError)
      }
    end

    context "when the method to preset memoization for is not defined" do
      it {
        expect { instance.preset_memo_wise(:undefined_method) { nil } }.
          to raise_error(ArgumentError)
      }
    end

    context "when there is no block passed in" do
      it {
        expect { instance.preset_memo_wise(:no_args) }.
          to raise_error(ArgumentError)
      }
    end
  end
end

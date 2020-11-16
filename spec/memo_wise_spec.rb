# frozen_string_literal: true

require "values"

RSpec.describe MemoWise do
  let(:class_with_memo) do
    Class.new do
      prepend MemoWise

      def initialize
        @no_args_counter = 0
        @with_positional_args_counter = 0
        @with_positional_and_splat_args_counter = 0
        @with_keyword_args_counter = 0
        @with_keyword_and_double_splat_args_counter = 0
        @with_positional_and_keyword_args_counter = 0
        @with_positional_splat_keyword_and_double_splat_args_counter = 0
        @special_chars_counter = 0
        @false_method_counter = 0
        @true_method_counter = 0
        @nil_method_counter = 0
        @private_memowise_method_counter = 0
        @protected_memowise_method_counter = 0
        @public_memowise_method_counter = 0
        @proc_method_counter = 0
      end

      attr_reader :no_args_counter,
                  :with_positional_args_counter,
                  :with_positional_and_splat_args_counter,
                  :with_keyword_args_counter,
                  :with_keyword_and_double_splat_args_counter,
                  :with_positional_and_keyword_args_counter,
                  :with_positional_splat_keyword_and_double_splat_args_counter,
                  :special_chars_counter,
                  :false_method_counter,
                  :true_method_counter,
                  :nil_method_counter,
                  :private_memowise_method_counter,
                  :protected_memowise_method_counter,
                  :public_memowise_method_counter,
                  :proc_method_counter

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

      def with_positional_and_splat_args(a, *args) # rubocop:disable Naming/MethodParameterName
        @with_positional_and_splat_args_counter += 1
        "with_positional_and_splat_args: a=#{a}, args=#{args}"
      end
      memo_wise :with_positional_and_splat_args

      def with_keyword_args(a:, b:) # rubocop:disable Naming/MethodParameterName
        @with_keyword_args_counter += 1
        "with_keyword_args: a=#{a}, b=#{b}"
      end
      memo_wise :with_keyword_args

      def with_keyword_and_double_splat_args(a:, **kwargs) # rubocop:disable Naming/MethodParameterName
        @with_keyword_and_double_splat_args_counter += 1
        "with_keyword_and_double_splat_args: a=#{a}, kwargs=#{kwargs}"
      end
      memo_wise :with_keyword_and_double_splat_args

      def with_positional_and_keyword_args(a, b:) # rubocop:disable Naming/MethodParameterName
        @with_positional_and_keyword_args_counter += 1
        "with_positional_and_keyword_args: a=#{a}, b=#{b}"
      end
      memo_wise :with_positional_and_keyword_args

      def with_positional_splat_keyword_and_double_splat_args(
        a, # rubocop:disable Naming/MethodParameterName
        *args,
        b:, # rubocop:disable Naming/MethodParameterName
        **kwargs
      )
        @with_positional_splat_keyword_and_double_splat_args_counter += 1
        "with_positional_splat_keyword_and_double_splat_args: "\
          "a=#{a}, args=#{args} b=#{b} kwargs=#{kwargs}"
      end
      memo_wise :with_positional_splat_keyword_and_double_splat_args

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
      private :private_memowise_method
      memo_wise :private_memowise_method

      def protected_memowise_method
        @protected_memowise_method_counter += 1
        "protected_memowise_method"
      end
      protected :protected_memowise_method
      memo_wise :protected_memowise_method

      def public_memowise_method
        @public_memowise_method_counter += 1
        "public_memowise_method"
      end
      memo_wise :public_memowise_method
      public :public_memowise_method

      def unmemoized_method; end

      def proc_method(proc)
        @proc_method_counter += 1
        proc.call
      end
      memo_wise :proc_method

      def explicit_block_method(&block); end

      def implicit_block_method
        yield
      end
      memo_wise :implicit_block_method
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

    it "memoizes methods with positional and splat arguments" do
      expect(Array.new(4) { instance.with_positional_and_splat_args(1, 2, 3) }).
        to all eq("with_positional_and_splat_args: a=1, args=[2, 3]")

      expect(Array.new(4) { instance.with_positional_and_splat_args(1, 3, 4) }).
        to all eq("with_positional_and_splat_args: a=1, args=[3, 4]")

      # This should be executed once for each set of arguments passed
      expect(instance.with_positional_and_splat_args_counter).to eq(2)
    end

    it "memoizes methods with keyword arguments" do
      expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
        to all eq("with_keyword_args: a=1, b=2")

      expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
        to all eq("with_keyword_args: a=2, b=3")

      # This should be executed once for each set of arguments passed
      expect(instance.with_keyword_args_counter).to eq(2)
    end

    it "memoizes methods with keyword and double-splat arguments" do
      expect(
        Array.new(4) do
          instance.with_keyword_and_double_splat_args(a: 1, b: 2, c: 3)
        end
      ).to all eq(
        "with_keyword_and_double_splat_args: a=1, kwargs={:b=>2, :c=>3}"
      )

      expect(
        Array.new(4) do
          instance.with_keyword_and_double_splat_args(a: 1, b: 2, c: 4)
        end
      ).to all eq(
        "with_keyword_and_double_splat_args: a=1, kwargs={:b=>2, :c=>4}"
      )

      # This should be executed once for each set of arguments passed
      expect(instance.with_keyword_and_double_splat_args_counter).to eq(2)
    end

    it "memoizes methods with positional and keyword arguments" do
      expect(
        Array.new(4) { instance.with_positional_and_keyword_args(1, b: 2) }
      ).to all eq("with_positional_and_keyword_args: a=1, b=2")

      expect(
        Array.new(4) { instance.with_positional_and_keyword_args(2, b: 3) }
      ).to all eq("with_positional_and_keyword_args: a=2, b=3")

      # This should be executed once for each set of arguments passed
      expect(instance.with_positional_and_keyword_args_counter).to eq(2)
    end

    it "memoizes methods with positional, splat, keyword, and double-splat "\
       "arguments" do
      expect(
        Array.new(4) do
          instance.with_positional_splat_keyword_and_double_splat_args(
            1,
            2,
            3,
            b: 4,
            c: 5,
            d: 6
          )
        end
      ).to all eq(
        "with_positional_splat_keyword_and_double_splat_args: "\
          "a=1, args=[2, 3] b=4 kwargs={:c=>5, :d=>6}"
      )

      expect(
        Array.new(4) do
          instance.with_positional_splat_keyword_and_double_splat_args(
            1,
            2,
            b: 4,
            c: 5
          )
        end
      ).to all eq(
        "with_positional_splat_keyword_and_double_splat_args: "\
          "a=1, args=[2] b=4 kwargs={:c=>5}"
      )

      # This should be executed once for each set of arguments passed
      expect(
        instance.with_positional_splat_keyword_and_double_splat_args_counter
      ).to eq(2)
    end

    it "memoizes methods with special characters in the name" do
      expect(Array.new(4) { instance.special_chars? }).
        to all eq("special_chars?")
      expect(instance.special_chars_counter).to eq(1)
    end

    it "memoizes methods set to false values" do
      expect(Array.new(4) { instance.false_method }).to all eq(false)
      expect(instance.false_method_counter).to eq(1)
    end

    it "memoizes methods set to nil values" do
      expect(Array.new(4) { instance.nil_method }).to all eq(nil)
      expect(instance.nil_method_counter).to eq(1)
    end

    it "does not memoize methods across instances" do
      instance2 = class_with_memo.new

      instance.no_args

      expect(instance.no_args_counter).to eq(1)
      expect(instance2.no_args_counter).to eq(0)
    end

    context "when memo_wise has *not* been called on a *class* method" do
      it "does *not* create class-level instance variable" do
        expect(class_with_memo.instance_variables).not_to include(:@_memo_wise)
      end
    end

    context "with class methods" do
      context "when defined with 'def self.'" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def self.class_method_counter
              @class_method_counter || 0
            end

            def self.self_dot_method(a, b: "default") # rubocop:disable Naming/MethodParameterName
              @class_method_counter = class_method_counter + 1
              "self_dot_method: a=#{a}, b=#{b}"
            end
            memo_wise :self_dot_method
          end
        end

        it "memoizes class methods defined with 'def self.'" do
          expect(Array.new(4) { class_with_memo.self_dot_method(1, b: 2) }).
            to all eq("self_dot_method: a=1, b=2")

          expect(Array.new(4) { class_with_memo.self_dot_method(1, b: 3) }).
            to all eq("self_dot_method: a=1, b=3")

          expect(class_with_memo.class_method_counter).to eq(2)
        end

        it "creates a class-level instance variable" do
          # NOTE: test implementation detail to ensure the inverse test is valid
          expect(class_with_memo.instance_variables).to include(:@_memo_wise)
        end
      end

      context "when defined with scope 'class << self'" do
        let(:class_with_memo) do
          Class.new do
            class << self
              prepend MemoWise

              def class_method_counter
                @class_method_counter || 0
              end

              def class_self_method(a, b: "default") # rubocop:disable Naming/MethodParameterName
                @class_method_counter = class_method_counter + 1
                "class_self_method: a=#{a}, b=#{b}"
              end
              memo_wise :class_self_method
            end
          end
        end

        it "memoizes class methods defined with scope 'class << self'" do
          expect(Array.new(4) { class_with_memo.class_self_method(1, b: 2) }).
            to all eq("class_self_method: a=1, b=2")

          expect(Array.new(4) { class_with_memo.class_self_method(1, b: 3) }).
            to all eq("class_self_method: a=1, b=3")

          expect(class_with_memo.class_method_counter).to eq(2)
        end

        it "creates a class-level instance variable" do
          # NOTE: this test ensure the inverse test above continues to be valid
          expect(class_with_memo.instance_variables).to include(:@_memo_wise)
        end
      end
    end

    context "with private methods" do
      it "keeps private methods private" do
        expect(instance.private_methods).to include(:private_memowise_method)
      end

      it "memoizes private methods" do
        expect(Array.new(4) do
          instance.send(:private_memowise_method)
        end).to all eq("private_memowise_method")
        expect(instance.private_memowise_method_counter).to eq(1)
      end
    end

    context "with public methods" do
      it "keeps public methods public" do
        expect(instance.public_methods).to include(:public_memowise_method)
      end

      it "memoizes public methods" do
        expect(Array.new(4) { instance.public_memowise_method }).
          to all eq("public_memowise_method")
        expect(instance.public_memowise_method_counter).to eq(1)
      end
    end

    context "with protected methods" do
      it "keeps protected methods protected" do
        expect(instance.protected_methods).
          to include(:protected_memowise_method)
      end

      it "memoizes protected methods" do
        expect(Array.new(4) do
          instance.send(:protected_memowise_method)
        end).to all eq("protected_memowise_method")
        expect(instance.protected_memowise_method_counter).to eq(1)
      end
    end

    context "when the name of the method to memoize is not a symbol" do
      let(:class_with_memo) do
        super().tap { |klass| klass.memo_wise "no_args" }
      end

      it { expect { instance }.to raise_error(ArgumentError) }
    end

    context "when the class is a Value class using the 'values' gem" do
      let(:external_counter) { [0] }

      let(:increment_proc) { -> { external_counter[0] += 1 } }

      let(:value_class) do
        Value.new(:increment_proc) do
          prepend MemoWise # rubocop:disable RSpec/DescribedClass

          def no_args
            increment_proc.call
            "no_args"
          end
          memo_wise :no_args
        end
      end

      let(:value_instance) { value_class.new(increment_proc) }

      it "memoizes methods" do
        expect(Array.new(4) { value_instance.no_args }).to all eq("no_args")
        expect(external_counter[0]).to eq(1)
      end
    end

    it "memoizes methods with proc arguments" do
      proc_param = proc { true }
      expect(Array.new(4) { instance.proc_method(proc_param) }).
        to all eq(true)

      expect(instance.proc_method_counter).to eq(1)
    end

    it "will not memoize methods with implicit block arguments" do
      expect { instance.implicit_block_method }.
        to raise_error(LocalJumpError)
    end

    it "will not memoize methods with explicit block arguments" do
      expect { instance.class.memo_wise(:explicit_block_method) }.
        to raise_error(
          ArgumentError,
          "Methods which take block arguments cannot be memoized"
        )
    end
  end

  describe "#reset_memo_wise" do
    context "when method_name is given" do
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

      it "resets memoization for methods for specific positional arguments" do
        instance.with_positional_args(1, 2)
        instance.with_positional_args(2, 3)
        instance.reset_memo_wise(:with_positional_args, 1, 2)

        expect(Array.new(4) { instance.with_positional_args(1, 2) }).
          to all eq("with_positional_args: a=1, b=2")

        expect(Array.new(4) { instance.with_positional_args(2, 3) }).
          to all eq("with_positional_args: a=2, b=3")

        # This should be executed twice for each set of arguments passed,
        # and a third time for the set of arguments that was reset.
        expect(instance.with_positional_args_counter).to eq(3)
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

      it "resets memoization for methods for specific keyword arguments" do
        instance.with_keyword_args(a: 1, b: 2)
        instance.with_keyword_args(a: 2, b: 3)
        instance.reset_memo_wise(:with_keyword_args, a: 1, b: 2)

        expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
          to all eq("with_keyword_args: a=1, b=2")

        expect(Array.new(4) { instance.with_keyword_args(a: 2, b: 3) }).
          to all eq("with_keyword_args: a=2, b=3")

        # This should be executed twice for each set of arguments passed,
        # and a third time for the set of arguments that was reset.
        expect(instance.with_keyword_args_counter).to eq(3)
      end

      it "resets memoization for methods with positional and keyword args" do
        instance.with_positional_and_keyword_args(1, b: 2)
        instance.with_positional_and_keyword_args(2, b: 3)
        instance.reset_memo_wise(:with_positional_and_keyword_args, 1, b: 2)

        expect(Array.new(4) do
          instance.with_positional_and_keyword_args(1, b: 2)
        end).to all eq("with_positional_and_keyword_args: a=1, b=2")

        expect(Array.new(4) do
          instance.with_positional_and_keyword_args(2, b: 3)
        end).to all eq("with_positional_and_keyword_args: a=2, b=3")

        # This should be executed once for each set of arguments passed,
        # and a third time for the set of arguments that was reset.
        expect(instance.with_positional_and_keyword_args_counter).to eq(3)
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

      it "resets memoization for methods set to nil values" do
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
        it do
          expect { instance.reset_memo_wise("no_args") }.
            to raise_error(ArgumentError)
        end
      end

      context "when the method to reset memoization for is not memoized" do
        it do
          expect { instance.reset_memo_wise(:unmemoized_method) { nil } }.
            to raise_error(ArgumentError)
        end
      end

      context "when the method to reset memoization for is not defined" do
        it do
          expect { instance.reset_memo_wise(:not_defined) }.
            to raise_error(ArgumentError)
        end
      end
    end

    context "when method_name is *not* given (e.g. 'reset all' mode)" do
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

          instance.reset_memo_wise
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

      it "resets memoization for methods set to false values" do
        expect(Array.new(4) { instance.false_method }).to all eq(false)
        expect(instance.false_method_counter).to eq(2)
      end

      it "resets memoization for methods set to nil values" do
        expect(Array.new(4) { instance.nil_method }).to all eq(nil)
        expect(instance.nil_method_counter).to eq(2)
      end

      it "does not reset memoization methods across instances" do
        instance2 = class_with_memo.new

        instance.no_args
        instance2.no_args

        instance.reset_memo_wise

        instance.no_args
        instance2.no_args

        expect(instance.no_args_counter).to eq(3)
        expect(instance2.no_args_counter).to eq(1)
      end

      context "when method_name=nil and args given" do
        it do
          expect { instance.reset_memo_wise(nil, 42) { nil } }.
            to raise_error(ArgumentError)
        end
      end

      context "when method_name=nil and kwargs given" do
        it do
          expect { instance.reset_memo_wise(foo: 42) { nil } }.
            to raise_error(ArgumentError)
        end
      end
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

      context "with positional and keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            instance.with_positional_and_keyword_args(1, b: 2)
            instance.with_positional_and_keyword_args(2, b: 3)
          end
        end

        it "presets memoization" do
          instance.preset_memo_wise(
            :with_positional_and_keyword_args, 1, b: 2
          ) { "first" }
          instance.preset_memo_wise(
            :with_positional_and_keyword_args, 2, b: 3
          ) { "second" }

          expect(Array.new(4) do
            instance.with_positional_and_keyword_args(1, b: 2)
          end).to all eq("first")

          expect(Array.new(4) do
            instance.with_positional_and_keyword_args(2, b: 3)
          end).to all eq("second")

          expect(instance.with_positional_and_keyword_args_counter).
            to eq(expected_counter)
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

    context "when memoized values were not already set" do
      it_behaves_like "presets memoization", overriding: false
    end

    context "when memoized values were already set" do
      it_behaves_like "presets memoization", overriding: true
    end

    it "does not preset memoization methods across instances" do
      instance2 = class_with_memo.new

      instance.preset_memo_wise(:no_args) { "preset_no_args" }

      expect(instance2.no_args).to eq("no_args")
      expect(instance2.no_args_counter).to eq(1)
    end

    context "when the method to preset memoization for is not memoized" do
      it do
        expect { instance.preset_memo_wise(:unmemoized_method) { nil } }.
          to raise_error(ArgumentError)
      end
    end

    context "when the method to preset memoization for is not defined" do
      it do
        expect { instance.preset_memo_wise(:undefined_method) { nil } }.
          to raise_error(ArgumentError)
      end
    end

    context "when there is no block passed in" do
      it do
        expect { instance.preset_memo_wise(:no_args) }.
          to raise_error(ArgumentError)
      end
    end
  end

  describe "private APIs" do
    describe ".method_visibility" do
      subject { described_class.method_visibility(String, method_name) }

      context "when method_name not a method on klass" do
        let(:method_name) { :not_a_method }

        it { expect { subject }.to raise_error(ArgumentError) }
      end
    end

    describe ".original_class_from_singleton" do
      subject { described_class.original_class_from_singleton(klass) }

      context "when klass is not a singleton class" do
        let(:klass) { String }

        it { expect { subject }.to raise_error(ArgumentError) }
      end

      context "when klass is a singleton class of an original class" do
        let(:klass) { original_class.singleton_class }

        context "when assigned to a constant (normal case)" do
          let(:original_class) { String }

          it { is_expected.to eq(original_class) }
        end

        context "when not assigned to a constant (anonymous case)" do
          let(:original_class) { class_with_memo }

          it { is_expected.to eq(original_class) }

          context "when singleton class #to_s convention not followed" do
            let(:klass) do
              super().tap do |sc|
                sc.define_singleton_method(:to_s) { "not following convention" }
              end
            end

            it { is_expected.to eq(original_class) }
          end
        end
      end
    end

    describe ".create_memo_wise_state!" do
      subject { described_class.create_memo_wise_state!(obj) }

      context "when obj already has instance variable '@_memo_wise'" do
        let(:obj) do
          Object.new.tap { |o| o.instance_variable_set(:@_memo_wise, 42) }
        end

        it { expect { subject }.to raise_error(ArgumentError) }
      end
    end
  end
end

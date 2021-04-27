# frozen_string_literal: true

require "values"

RSpec.describe MemoWise do
  ##
  # Shared contexts for setting up for testing:
  #   * Instance methods
  #   * Class methods defined via: 'def self.foo ...'
  #   * Class methods defined via: 'class << self; def foo ...'
  ##

  shared_context "with context for instance methods" do
    let(:instance) { class_with_memo.new }

    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :instance
        )

        # Counter for calls to a protected method
        def protected_memowise_method_counter
          @protected_memowise_method_counter || 0
        end

        # A memoized protected method - only makes sense as an instance method
        def protected_memowise_method
          @protected_memowise_method_counter =
            protected_memowise_method_counter + 1
          "protected_memowise_method"
        end
        protected :protected_memowise_method
        memo_wise :protected_memowise_method

        # Counter for calls to class method '.positional_args', see below.
        def self.class_positional_args_counter
          @class_positional_args_counter || 0
        end

        # See: "with class method with same name as memoized instance method"
        #
        # Used by spec below to verify that `memo_wise :with_positional_args`
        # memoizes only the instance method, and not this class method sharing
        # the same name.
        def self.with_positional_args(a, b) # rubocop:disable Naming/MethodParameterName
          @class_positional_args_counter = class_positional_args_counter + 1
          "class_with_positional_args: a=#{a}, b=#{b}"
        end
      end
    end
  end

  shared_context "with context for class methods via 'def self.'" do
    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :self_dot
        )

        # Counter for calls to instance method '#with_keyword_args', see below.
        def instance_with_keyword_args_counter
          @instance_with_keyword_args_counter || 0
        end

        # See: "doesn't memoize instance methods when passed self: keyword"
        #
        # Used by spec below to verify that `memo_wise self: :with_keyword_args`
        # memoizes only the class method, and not this instance method sharing
        # the same name.
        def with_keyword_args(a:, b:) # rubocop:disable Naming/MethodParameterName
          @instance_with_keyword_args_counter =
            instance_with_keyword_args_counter + 1
          "instance_with_keyword_args_counter: a=#{a}, b=#{b}"
        end
      end
    end
  end

  shared_context "with context for class methods via scope 'class << self'" do
    let(:class_with_memo) do
      Class.new do
        class << self
          prepend MemoWise

          DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
            target: self,
            via: :instance
          )
        end
      end
    end
  end

  ##
  # Specs start here: one 'describe' block for each public API method
  ##

  describe "#memo_wise" do
    shared_examples "#memo_wise shared examples" do
      #
      # These examples depend on `let(:target)` -- can be an instance or a class
      #

      it "memoizes methods with no arguments" do
        expect(Array.new(4) { target.no_args }).to all eq("no_args")
        expect(target.no_args_counter).to eq(1)
      end

      it "memoizes methods with one positional argument" do
        expect(Array.new(4) { target.with_one_positional_arg(1) }).
          to all eq("with_one_positional_arg: a=1")

        expect(Array.new(4) { target.with_one_positional_arg(2) }).
          to all eq("with_one_positional_arg: a=2")

        # This should be executed once for each set of arguments passed
        expect(target.with_one_positional_arg_counter).to eq(2)
      end

      it "memoizes methods with positional arguments" do
        expect(Array.new(4) { target.with_positional_args(1, 2) }).
          to all eq("with_positional_args: a=1, b=2")

        expect(Array.new(4) { target.with_positional_args(1, 3) }).
          to all eq("with_positional_args: a=1, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_args_counter).to eq(2)
      end

      it "memoizes methods with positional and splat arguments" do
        expect(
          Array.new(4) do
            target.with_positional_and_splat_args(1, 2, 3)
          end
        ).to all eq("with_positional_and_splat_args: a=1, args=[2, 3]")

        expect(
          Array.new(4) do
            target.with_positional_and_splat_args(1, 3, 4)
          end
        ).to all eq("with_positional_and_splat_args: a=1, args=[3, 4]")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_and_splat_args_counter).to eq(2)
      end

      it "memoizes methods with one keyword argument" do
        expect(Array.new(4) { target.with_one_keyword_arg(a: 1) }).
          to all eq("with_one_keyword_arg: a=1")

        expect(Array.new(4) { target.with_one_keyword_arg(a: 2) }).
          to all eq("with_one_keyword_arg: a=2")

        # This should be executed once for each set of arguments passed
        expect(target.with_one_keyword_arg_counter).to eq(2)
      end

      it "memoizes methods with keyword arguments" do
        expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).
          to all eq("with_keyword_args: a=1, b=2")

        expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).
          to all eq("with_keyword_args: a=2, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_keyword_args_counter).to eq(2)
      end

      it "memoizes methods with keyword and double-splat arguments" do
        expect(
          Array.new(4) do
            target.with_keyword_and_double_splat_args(a: 1, b: 2, c: 3)
          end
        ).to all eq(
          "with_keyword_and_double_splat_args: a=1, kwargs={:b=>2, :c=>3}"
        )

        expect(
          Array.new(4) do
            target.with_keyword_and_double_splat_args(a: 1, b: 2, c: 4)
          end
        ).to all eq(
          "with_keyword_and_double_splat_args: a=1, kwargs={:b=>2, :c=>4}"
        )

        # This should be executed once for each set of arguments passed
        expect(target.with_keyword_and_double_splat_args_counter).to eq(2)
      end

      it "memoizes methods with positional and keyword arguments" do
        expect(
          Array.new(4) { target.with_positional_and_keyword_args(1, b: 2) }
        ).to all eq("with_positional_and_keyword_args: a=1, b=2")

        expect(
          Array.new(4) { target.with_positional_and_keyword_args(2, b: 3) }
        ).to all eq("with_positional_and_keyword_args: a=2, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_and_keyword_args_counter).to eq(2)
      end

      it "memoizes methods with positional, splat, keyword, and double-splat "\
         "arguments" do
        expect(
          Array.new(4) do
            target.with_positional_splat_keyword_and_double_splat_args(
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
            target.with_positional_splat_keyword_and_double_splat_args(
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
          target.with_positional_splat_keyword_and_double_splat_args_counter
        ).to eq(2)
      end

      it "memoizes methods with special characters in the name" do
        expect(Array.new(4) { target.special_chars? }).
          to all eq("special_chars?")
        expect(target.special_chars_counter).to eq(1)
      end

      it "memoizes methods set to false values" do
        expect(Array.new(4) { target.false_method }).to all eq(false)
        expect(target.false_method_counter).to eq(1)
      end

      it "memoizes methods set to nil values" do
        expect(Array.new(4) { target.nil_method }).to all eq(nil)
        expect(target.nil_method_counter).to eq(1)
      end

      context "with private methods" do
        it "keeps private methods private" do
          expect(target.private_methods).to include(:private_memowise_method)
        end

        it "memoizes private methods" do
          expect(Array.new(4) do
            target.send(:private_memowise_method)
          end).to all eq("private_memowise_method")
          expect(target.private_memowise_method_counter).to eq(1)
        end
      end

      context "with public methods" do
        it "keeps public methods public" do
          expect(target.public_methods).to include(:public_memowise_method)
        end

        it "memoizes public methods" do
          expect(Array.new(4) { target.public_memowise_method }).
            to all eq("public_memowise_method")
          expect(target.public_memowise_method_counter).to eq(1)
        end
      end

      it "memoizes methods with proc arguments" do
        proc_param = proc { true }
        expect(Array.new(4) { target.proc_method(proc_param) }).
          to all eq(true)

        expect(target.proc_method_counter).to eq(1)
      end

      it "will not memoize methods with implicit block arguments" do
        expect { target.implicit_block_method }.
          to raise_error(LocalJumpError)
      end

      it "will not memoize methods with explicit block arguments" do
        expect { target.explicit_block_method { nil } }.
          to raise_error(LocalJumpError)
      end
    end

    context "with instance methods" do
      include_context "with context for instance methods"

      # Use the instance as the target of "#memo_wise shared examples"
      let(:target) { instance }

      it_behaves_like "#memo_wise shared examples"

      it "does not memoize methods across instances" do
        instance2 = class_with_memo.new

        instance.no_args

        expect(instance.no_args_counter).to eq(1)
        expect(instance2.no_args_counter).to eq(0)
      end

      context "with protected methods" do
        it "keeps protected methods protected" do
          expect(target.protected_methods).
            to include(:protected_memowise_method)
        end

        it "memoizes protected methods" do
          expect(Array.new(4) do
            target.send(:protected_memowise_method)
          end).to all eq("protected_memowise_method")
          expect(target.protected_memowise_method_counter).to eq(1)
        end
      end

      context "when memo_wise has *not* been called on a *class* method" do
        it "does *not* create class-level instance variable" do
          expect(
            class_with_memo.instance_variables
          ).not_to include(:@_memo_wise)
        end
      end

      context "when instances are created with Class#allocate" do
        let(:instance) { class_with_memo.allocate }

        it "memoizes correctly" do
          expect(Array.new(4) { instance.no_args }).to all eq("no_args")
          expect(instance.no_args_counter).to eq(1)
        end
      end

      context "when the name of the method to memoize is not a symbol" do
        let(:class_with_memo) do
          super().tap { |klass| klass.memo_wise "no_args" }
        end

        it { expect { instance }.to raise_error(ArgumentError) }
      end

      context "with class method with same name as memoized instance method" do
        it "does not memoize the class methods" do
          expect(Array.new(4) { class_with_memo.with_positional_args(1, 2) }).
            to all eq("class_with_positional_args: a=1, b=2")

          expect(class_with_memo.class_positional_args_counter).to eq(4)
        end
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
    end

    context "with class methods" do
      context "when defined with 'def self.'" do
        include_context "with context for class methods via 'def self.'"

        # Use the class as the target of "#memo_wise shared examples"
        let(:target) { class_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a class-level instance variable" do
          # NOTE: test implementation detail to ensure the inverse test is valid
          expect(class_with_memo.instance_variables).to include(:@_memo_wise)
        end

        context "with instance methods with the same name as class methods" do
          let(:instance) { class_with_memo.new }

          it "doesn't memoize instance methods when passed self: keyword" do
            expect(Array.new(4) { instance.with_keyword_args(a: 1, b: 2) }).
              to all eq("instance_with_keyword_args_counter: a=1, b=2")

            expect(instance.instance_with_keyword_args_counter).to eq(4)
          end
        end

        context "when an invalid hash key is passed to .memo_wise" do
          let(:class_with_memo) do
            Class.new do
              prepend MemoWise

              def self.class_method; end
            end
          end

          it "raises an error when passing a key which is not `self:`" do
            expect { class_with_memo.send(:memo_wise, bad_key: :class_method) }.
              to raise_error(
                ArgumentError,
                "`:self` is the only key allowed in memo_wise"
              )
          end
        end
      end

      context "when defined with scope 'class << self'" do
        include_context "with context for class methods via scope "\
                        "'class << self'"

        # Use the class as the target of "#memo_wise shared examples"
        let(:target) { class_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a class-level instance variable" do
          # NOTE: this test ensure the inverse test above continues to be valid
          expect(class_with_memo.instance_variables).to include(:@_memo_wise)
        end
      end
    end
  end

  describe "#reset_memo_wise" do
    context "with instance methods" do
      include_context "with context for instance methods"

      context "when method_name is given" do
        it "resets memoization for methods with no arguments" do
          instance.no_args
          instance.reset_memo_wise(:no_args)
          expect(Array.new(4) { instance.no_args }).to all eq("no_args")
          expect(instance.no_args_counter).to eq(2)
        end

        it "resets memoization for methods with one positional argument" do
          instance.with_one_positional_arg(1)
          instance.with_one_positional_arg(2)
          instance.reset_memo_wise(:with_one_positional_arg)

          expect(Array.new(4) { instance.with_one_positional_arg(1) }).
            to all eq("with_one_positional_arg: a=1")

          expect(Array.new(4) { instance.with_one_positional_arg(2) }).
            to all eq("with_one_positional_arg: a=2")

          # This should be executed twice for each set of arguments passed
          expect(instance.with_one_positional_arg_counter).to eq(4)
        end

        it "resets memoization for methods for one specific positional "\
           "argument" do
          instance.with_one_positional_arg(1)
          instance.with_one_positional_arg(2)
          instance.reset_memo_wise(:with_one_positional_arg, 1)

          expect(Array.new(4) { instance.with_one_positional_arg(1) }).
            to all eq("with_one_positional_arg: a=1")

          expect(Array.new(4) { instance.with_one_positional_arg(2) }).
            to all eq("with_one_positional_arg: a=2")

          # This should be executed twice for each set of arguments passed,
          # and a third time for the argument that was reset.
          expect(instance.with_one_positional_arg_counter).to eq(3)
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

        it "resets memoization for methods with one keyword argument" do
          instance.with_one_keyword_arg(a: 1)
          instance.with_one_keyword_arg(a: 2)
          instance.reset_memo_wise(:with_one_keyword_arg)

          expect(Array.new(4) { instance.with_one_keyword_arg(a: 1) }).
            to all eq("with_one_keyword_arg: a=1")

          expect(Array.new(4) { instance.with_one_keyword_arg(a: 2) }).
            to all eq("with_one_keyword_arg: a=2")

          # This should be executed twice for each set of arguments passed
          expect(instance.with_one_keyword_arg_counter).to eq(4)
        end

        it "resets memoization for methods for one specific keyword argument" do
          instance.with_one_keyword_arg(a: 1)
          instance.with_one_keyword_arg(a: 2)
          instance.reset_memo_wise(:with_one_keyword_arg, a: 1)

          expect(Array.new(4) { instance.with_one_keyword_arg(a: 1) }).
            to all eq("with_one_keyword_arg: a=1")

          expect(Array.new(4) { instance.with_one_keyword_arg(a: 2) }).
            to all eq("with_one_keyword_arg: a=2")

          # This should be executed twice for each set of arguments passed,
          # and a third time for the argument that was reset.
          expect(instance.with_one_keyword_arg_counter).to eq(3)
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

        it "resets memoization for methods with special characters in the "\
           "name" do
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

        it "resets memoization for private methods" do
          instance.send(:private_memowise_method)
          instance.reset_memo_wise(:private_memowise_method)
          expect(Array.new(4) { instance.send(:private_memowise_method) }).
            to all eq("private_memowise_method")
          expect(instance.private_memowise_method_counter).to eq(2)
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

        context "when args are given" do
          context "when no value is memoized for the method" do
            it "doesn't raise an error" do
              expect { instance.reset_memo_wise(:with_positional_args, 1, 2) }.
                not_to raise_error(NoMethodError)
            end
          end
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

        it "resets memoization for methods with special characters in the "\
           "name" do
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
  end

  describe "#preset_memo_wise" do
    shared_examples "#preset_memo_wise shared examples" do |overriding:|
      let(:expected_counter) { overriding ? 1 : 0 }

      context "with no args" do
        before(:each) { target.no_args if overriding }

        it "presets memoization" do
          target.preset_memo_wise(:no_args) { "preset_no_args" }

          expect(Array.new(4) { target.no_args }).
            to all eq("preset_no_args")
          expect(target.no_args_counter).to eq(expected_counter)
        end
      end

      context "with one positional arg" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_one_positional_arg(1)
            target.with_one_positional_arg(2)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(:with_one_positional_arg, 1) { "preset1" }
          target.preset_memo_wise(:with_one_positional_arg, 2) { "preset2" }

          expect(Array.new(4) { target.with_one_positional_arg(1) }).
            to all eq("preset1")

          expect(Array.new(4) { target.with_one_positional_arg(2) }).
            to all eq("preset2")

          expect(target.with_one_positional_arg_counter).
            to eq(expected_counter)
        end
      end

      context "with positional args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_positional_args(1, 2)
            target.with_positional_args(3, 4)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(:with_positional_args, 1, 2) { "preset1" }
          target.preset_memo_wise(:with_positional_args, 3, 4) { "preset3" }

          expect(Array.new(4) { target.with_positional_args(1, 2) }).
            to all eq("preset1")

          expect(Array.new(4) { target.with_positional_args(3, 4) }).
            to all eq("preset3")

          expect(target.with_positional_args_counter).
            to eq(expected_counter)
        end
      end

      context "with optional positional args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_optional_positional_args(1, 2)
            target.with_optional_positional_args(3, 4)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(
            :with_optional_positional_args,
            1,
            2
          ) { "preset1" }
          target.preset_memo_wise(
            :with_optional_positional_args,
            3,
            4
          ) { "preset3" }

          expect(Array.new(4) do
            target.with_optional_positional_args(1, 2)
          end).to all eq("preset1")

          expect(Array.new(4) do
            target.with_optional_positional_args(3, 4)
          end).to all eq("preset3")

          expect(target.with_optional_positional_args_counter).
            to eq(expected_counter)
        end
      end

      context "with one keyword arg" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_one_keyword_arg(a: 1)
            target.with_one_keyword_arg(a: 2)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(:with_one_keyword_arg, a: 1) { "1st" }
          target.preset_memo_wise(:with_one_keyword_arg, a: 2) { "2nd" }

          expect(Array.new(4) { target.with_one_keyword_arg(a: 1) }).
            to all eq("1st")

          expect(Array.new(4) { target.with_one_keyword_arg(a: 2) }).
            to all eq("2nd")

          expect(target.with_one_keyword_arg_counter).
            to eq(expected_counter)
        end
      end

      context "with keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_keyword_args(a: 1, b: 2)
            target.with_keyword_args(a: 2, b: 3)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(:with_keyword_args, a: 1, b: 2) { "1st" }
          target.preset_memo_wise(:with_keyword_args, a: 2, b: 3) { "2nd" }

          expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).
            to all eq("1st")

          expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).
            to all eq("2nd")

          expect(target.with_keyword_args_counter).to eq(expected_counter)
        end
      end

      context "with optional keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_optional_keyword_args(a: 1, b: 2)
            target.with_optional_keyword_args(a: 2, b: 3)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(
            :with_optional_keyword_args,
            a: 1,
            b: 2
          ) { "1st" }
          target.preset_memo_wise(
            :with_optional_keyword_args,
            a: 2,
            b: 3
          ) { "2nd" }

          expect(Array.new(4) do
            target.with_optional_keyword_args(a: 1, b: 2)
          end).to all eq("1st")

          expect(Array.new(4) do
            target.with_optional_keyword_args(a: 2, b: 3)
          end).to all eq("2nd")

          expect(target.with_optional_keyword_args_counter).
            to eq(expected_counter)
        end
      end

      context "with positional and keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_positional_and_keyword_args(1, b: 2)
            target.with_positional_and_keyword_args(2, b: 3)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(
            :with_positional_and_keyword_args, 1, b: 2
          ) { "first" }
          target.preset_memo_wise(
            :with_positional_and_keyword_args, 2, b: 3
          ) { "second" }

          expect(Array.new(4) do
            target.with_positional_and_keyword_args(1, b: 2)
          end).to all eq("first")

          expect(Array.new(4) do
            target.with_positional_and_keyword_args(2, b: 3)
          end).to all eq("second")

          expect(target.with_positional_and_keyword_args_counter).
            to eq(expected_counter)
        end
      end

      context "with optional positional and keyword args" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_optional_positional_and_keyword_args(1, b: 2)
            target.with_optional_positional_and_keyword_args(2, b: 3)
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(
            :with_optional_positional_and_keyword_args, 1, b: 2
          ) { "first" }
          target.preset_memo_wise(
            :with_optional_positional_and_keyword_args, 2, b: 3
          ) { "second" }

          expect(Array.new(4) do
            target.with_optional_positional_and_keyword_args(1, b: 2)
          end).to all eq("first")

          expect(Array.new(4) do
            target.with_optional_positional_and_keyword_args(2, b: 3)
          end).to all eq("second")

          expect(target.with_optional_positional_and_keyword_args_counter).
            to eq(expected_counter)
        end
      end

      context "with special chars" do
        before(:each) { target.special_chars? if overriding }

        it "presets memoization" do
          target.preset_memo_wise(:special_chars?) do
            "preset_special_chars?"
          end
          expect(Array.new(4) { target.special_chars? }).
            to all eq("preset_special_chars?")
          expect(target.special_chars_counter).to eq(expected_counter)
        end
      end

      context "with methods set to false values" do
        before(:each) { target.true_method if overriding }

        it "presets memoization" do
          target.preset_memo_wise(:true_method) { false }
          expect(Array.new(4) { target.true_method }).to all eq(false)
          expect(target.true_method_counter).to eq(expected_counter)
        end
      end

      context "with methods set to nil values" do
        before(:each) { target.no_args if overriding }

        it "presets memoization" do
          target.preset_memo_wise(:no_args) { nil }
          expect(Array.new(4) { target.no_args }).to all eq(nil)
          expect(target.no_args_counter).to eq(expected_counter)
        end
      end
    end

    context "with instance methods" do
      include_context "with context for instance methods"

      # Use the instance as the target of "#preset_memo_wise shared examples"
      let(:target) { instance }

      context "when memoized values were not already set" do
        it_behaves_like "#preset_memo_wise shared examples", overriding: false
      end

      context "when memoized values were already set" do
        it_behaves_like "#preset_memo_wise shared examples", overriding: true
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

    context "with class methods" do
      context "when defined with 'def self.'" do
        include_context "with context for class methods via 'def self.'"

        # Use the class as the target of "#preset_memo_wise shared examples"
        let(:target) { class_with_memo }

        context "when memoized values were not already set" do
          it_behaves_like "#preset_memo_wise shared examples", overriding: false
        end

        context "when memoized values were already set" do
          it_behaves_like "#preset_memo_wise shared examples", overriding: true
        end
      end

      context "when defined with scope 'class << self'" do
        include_context "with context for class methods via scope "\
                        "'class << self'"

        # Use the class as the target of "#preset_memo_wise shared examples"
        let(:target) { class_with_memo }

        context "when memoized values were not already set" do
          it_behaves_like "#preset_memo_wise shared examples", overriding: false
        end

        context "when memoized values were already set" do
          it_behaves_like "#preset_memo_wise shared examples", overriding: true
        end
      end
    end
  end

  describe "prepend MemoWise" do
    context "when the class's initializer take arguments" do
      context "when it only takes positional arguments" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def initialize(arg); end
          end
        end

        it "does not raise an error when initializing the class" do
          expect { class_with_memo.new(:pos) }.to_not raise_error
        end
      end

      context "when it only takes keyword arguments" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def initialize(kwarg:); end
          end
        end

        it "does not raise an error when initializing the class" do
          expect { class_with_memo.new(kwarg: :kw) }.to_not raise_error
        end
      end

      context "when it take both positional and keyword arguments" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def initialize(arg, kwarg:); end
          end
        end

        it "does not raise an error when initializing the class" do
          expect { class_with_memo.new(:pos, kwarg: :kw) }.to_not raise_error
        end
      end

      context "when the method takes positional arguments, keyword arguments, "\
              "and a block" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def initialize(arg, kwarg:, &block); end
          end
        end

        it "does not raise an error when initializing the class" do
          expect { class_with_memo.new(:pos, kwarg: :kw) { true } }.
            to_not raise_error
        end
      end
    end

    context "when serializing using Marshal" do
      let(:class_with_memo) do
        Class.new do
          prepend MemoWise

          attr_reader :name, :name_upper_counter

          def initialize(name:)
            @name = name
            @name_upper_counter = 0
          end

          def name_upper
            @name_upper_counter += 1
            name.upcase
          end
          memo_wise :name_upper
        end
      end

      before :each do
        stub_const("ClassForTest", class_with_memo)
      end

      it "dumps and loads without error" do
        obj1 = ClassForTest.new(name: "foo")
        obj2 = Marshal.load(Marshal.dump(obj1))
        expect(obj2.class).to be(ClassForTest)
        expect(obj2.name).to eq(obj1.name)
      end

      it "dumps and loads memoized state" do
        obj1 = ClassForTest.new(name: "foo")
        obj1.name_upper
        obj2 = Marshal.load(Marshal.dump(obj1))

        expect { obj2.name_upper }.
          not_to change { obj2.name_upper_counter }.
          from(1)

        expect(obj2.name_upper).to eq("FOO")
      end
    end
  end

  ##
  # Private API specs start here, until such time as we separate them out
  ##

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

        context "when assigned to a constant" do
          let(:original_class) { String }

          it { is_expected.to eq(original_class) }
        end

        context "when singleton class #to_s convention not followed" do
          include_context "with context for instance methods"

          let(:original_class) { class_with_memo }
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
end

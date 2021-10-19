# frozen_string_literal: true

RSpec.describe MemoWise do
  describe "#reset_memo_wise" do
    shared_examples "#reset_memo_wise shared examples" do
      context "when method_name is given" do
        it "resets memoization for methods with no arguments" do
          target.no_args
          target.reset_memo_wise(:no_args)
          expect(Array.new(4) { target.no_args }).to all eq("no_args")
          expect(target.no_args_counter).to eq(2)
        end

        it "resets memoization for methods with one positional argument" do
          target.with_one_positional_arg(1)
          target.with_one_positional_arg(2)
          target.reset_memo_wise(:with_one_positional_arg)

          expect(Array.new(4) { target.with_one_positional_arg(1) }).to all eq("with_one_positional_arg: a=1")
          expect(Array.new(4) { target.with_one_positional_arg(2) }).to all eq("with_one_positional_arg: a=2")

          # This should be executed twice for each set of arguments passed
          expect(target.with_one_positional_arg_counter).to eq(4)
        end

        it "resets memoization for methods for one specific positional argument" do
          target.with_one_positional_arg(1)
          target.with_one_positional_arg(2)
          target.reset_memo_wise(:with_one_positional_arg, 1)

          expect(Array.new(4) { target.with_one_positional_arg(1) }).to all eq("with_one_positional_arg: a=1")
          expect(Array.new(4) { target.with_one_positional_arg(2) }).to all eq("with_one_positional_arg: a=2")

          # This should be executed once for each set of arguments passed,
          # and a third time for the argument that was reset.
          expect(target.with_one_positional_arg_counter).to eq(3)
        end

        it "resets memoization for methods with one specific positional argument that is an array" do
          target.with_one_positional_arg([1])
          target.with_one_positional_arg([2])
          target.reset_memo_wise(:with_one_positional_arg, [1])

          expect(Array.new(4) { target.with_one_positional_arg([1]) }).to all eq("with_one_positional_arg: a=[1]")
          expect(Array.new(4) { target.with_one_positional_arg([2]) }).to all eq("with_one_positional_arg: a=[2]")

          # This should be executed once for each set of arguments passed,
          # and a third time for the argument that was reset.
          expect(target.with_one_positional_arg_counter).to eq(3)
        end

        it "resets memoization for methods with positional arguments" do
          target.with_positional_args(1, 2)
          target.with_positional_args(2, 3)
          target.reset_memo_wise(:with_positional_args)

          expect(Array.new(4) { target.with_positional_args(1, 2) }).to all eq("with_positional_args: a=1, b=2")
          expect(Array.new(4) { target.with_positional_args(1, 3) }).to all eq("with_positional_args: a=1, b=3")

          # This should be executed twice for each set of arguments passed
          expect(target.with_positional_args_counter).to eq(4)
        end

        it "resets memoization for methods for specific positional arguments" do
          target.with_positional_args(1, 2)
          target.with_positional_args(2, 3)
          target.reset_memo_wise(:with_positional_args, 1, 2)

          expect(Array.new(4) { target.with_positional_args(1, 2) }).to all eq("with_positional_args: a=1, b=2")
          expect(Array.new(4) { target.with_positional_args(2, 3) }).to all eq("with_positional_args: a=2, b=3")

          # This should be executed once for each set of arguments passed,
          # and a third time for the set of arguments that was reset.
          expect(target.with_positional_args_counter).to eq(3)
        end

        it "resets memoization for methods with one keyword argument" do
          target.with_one_keyword_arg(a: 1)
          target.with_one_keyword_arg(a: 2)
          target.reset_memo_wise(:with_one_keyword_arg)

          expect(Array.new(4) { target.with_one_keyword_arg(a: 1) }).to all eq("with_one_keyword_arg: a=1")
          expect(Array.new(4) { target.with_one_keyword_arg(a: 2) }).to all eq("with_one_keyword_arg: a=2")

          # This should be executed twice for each set of arguments passed
          expect(target.with_one_keyword_arg_counter).to eq(4)
        end

        it "resets memoization for methods for one specific keyword argument" do
          target.with_one_keyword_arg(a: 1)
          target.with_one_keyword_arg(a: 2)
          target.reset_memo_wise(:with_one_keyword_arg, a: 1)

          expect(Array.new(4) { target.with_one_keyword_arg(a: 1) }).to all eq("with_one_keyword_arg: a=1")
          expect(Array.new(4) { target.with_one_keyword_arg(a: 2) }).to all eq("with_one_keyword_arg: a=2")

          # This should be executed once for each set of arguments passed,
          # and a third time for the argument that was reset.
          expect(target.with_one_keyword_arg_counter).to eq(3)
        end

        it "resets memoization for methods with keyword arguments" do
          target.with_keyword_args(a: 1, b: 2)
          target.with_keyword_args(a: 2, b: 3)
          target.reset_memo_wise(:with_keyword_args)

          expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).to all eq("with_keyword_args: a=1, b=2")
          expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).to all eq("with_keyword_args: a=2, b=3")

          # This should be executed twice for each set of arguments passed
          expect(target.with_keyword_args_counter).to eq(4)
        end

        it "resets memoization for methods for specific keyword arguments" do
          target.with_keyword_args(a: 1, b: 2)
          target.with_keyword_args(a: 2, b: 3)
          target.reset_memo_wise(:with_keyword_args, a: 1, b: 2)

          expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).to all eq("with_keyword_args: a=1, b=2")
          expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).to all eq("with_keyword_args: a=2, b=3")

          # This should be executed once for each set of arguments passed,
          # and a third time for the set of arguments that was reset.
          expect(target.with_keyword_args_counter).to eq(3)
        end

        it "resets memoization for methods with optional positional arguments" do
          target.with_optional_positional_args(2, 3)
          target.with_optional_positional_args(2, 4)
          target.reset_memo_wise(:with_optional_positional_args)

          expect(Array.new(4) { target.with_optional_positional_args(2, 3) }).
            to all eq("with_optional_positional_args: a=2, b=3")

          expect(Array.new(4) { target.with_optional_positional_args(2, 4) }).
            to all eq("with_optional_positional_args: a=2, b=4")

          # This should be executed twice for each set of arguments passed
          expect(target.with_optional_positional_args_counter).to eq(4)
        end

        it "resets memoization for methods with specific optional positional arguments" do
          target.with_optional_positional_args(2, 3)
          target.with_optional_positional_args(2, 4)
          target.reset_memo_wise(:with_optional_positional_args, 2, 3)

          expect(Array.new(4) { target.with_optional_positional_args(2, 3) }).
            to all eq("with_optional_positional_args: a=2, b=3")

          expect(Array.new(4) { target.with_optional_positional_args(2, 4) }).
            to all eq("with_optional_positional_args: a=2, b=4")

          # This should be executed once for each set of arguments passed,
          # and a third time for the set of arguments that was reset.
          expect(target.with_optional_positional_args_counter).to eq(3)
        end

        it "resets memoization for methods with optional keyword arguments" do
          target.with_optional_keyword_args(a: 2, b: 3)
          target.with_optional_keyword_args(a: 2, b: 4)
          target.reset_memo_wise(:with_optional_keyword_args)

          expect(Array.new(4) { target.with_optional_keyword_args(a: 2, b: 3) }).
            to all eq("with_optional_keyword_args: a=2, b=3")

          expect(Array.new(4) { target.with_optional_keyword_args(a: 2, b: 4) }).
            to all eq("with_optional_keyword_args: a=2, b=4")

          # This should be executed twice for each set of arguments passed
          expect(target.with_optional_keyword_args_counter).to eq(4)
        end

        it "resets memoization for methods with specific optional keyword arguments" do
          target.with_optional_keyword_args(a: 2, b: 3)
          target.with_optional_keyword_args(a: 2, b: 4)
          target.reset_memo_wise(:with_optional_keyword_args, a: 2, b: 3)

          expect(Array.new(4) { target.with_optional_keyword_args(a: 2, b: 3) }).
            to all eq("with_optional_keyword_args: a=2, b=3")

          expect(Array.new(4) { target.with_optional_keyword_args(a: 2, b: 4) }).
            to all eq("with_optional_keyword_args: a=2, b=4")

          # This should be executed once for each set of arguments passed,
          # and a third time for the set of arguments that was reset.
          expect(target.with_optional_keyword_args_counter).to eq(3)
        end

        it "resets memoization for methods with positional and keyword arguments" do
          target.with_positional_and_keyword_args(1, b: 2)
          target.with_positional_and_keyword_args(2, b: 3)
          target.reset_memo_wise(:with_positional_and_keyword_args, 1, b: 2)

          expect(Array.new(4) { target.with_positional_and_keyword_args(1, b: 2) }).
            to all eq("with_positional_and_keyword_args: a=1, b=2")

          expect(Array.new(4) { target.with_positional_and_keyword_args(2, b: 3) }).
            to all eq("with_positional_and_keyword_args: a=2, b=3")

          # This should be executed once for each set of arguments passed,
          # and a third time for the set of arguments that was reset.
          expect(target.with_positional_and_keyword_args_counter).to eq(3)
        end

        it "resets memoization for methods with special characters in the name" do
          target.special_chars?
          target.reset_memo_wise(:special_chars?)
          expect(Array.new(4) { target.special_chars? }).to all eq("special_chars?")
          expect(target.special_chars_counter).to eq(2)
        end

        it "resets memoization for methods set to false values" do
          target.false_method
          target.reset_memo_wise(:false_method)
          expect(Array.new(4) { target.false_method }).to all eq(false)
          expect(target.false_method_counter).to eq(2)
        end

        it "resets memoization for methods set to nil values" do
          target.nil_method
          target.reset_memo_wise(:nil_method)
          expect(Array.new(4) { target.nil_method }).to all eq(nil)
          expect(target.nil_method_counter).to eq(2)
        end

        it "resets memoization for private methods" do
          target.send(:private_memowise_method)
          target.reset_memo_wise(:private_memowise_method)
          expect(Array.new(4) { target.send(:private_memowise_method) }).to all eq("private_memowise_method")
          expect(target.private_memowise_method_counter).to eq(2)
        end

        context "when no value is memoized for the method" do
          it "doesn't raise an error for methods with one positional arg" do
            expect { target.reset_memo_wise(:with_one_positional_arg) }.not_to raise_error
          end

          it "doesn't raise an error for methods with one specific positional argument" do
            expect { target.reset_memo_wise(:with_one_positional_arg, 1) }.not_to raise_error
          end

          it "doesn't raise an error for methods with one keyword arg" do
            expect { target.reset_memo_wise(:with_one_keyword_arg) }.not_to raise_error
          end

          it "doesn't raise an error for methods with one specific keyword argument" do
            expect { target.reset_memo_wise(:with_one_keyword_arg, a: 1) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional positional arguments" do
            expect { target.reset_memo_wise(:with_optional_positional_args) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional positional arguments provided" do
            expect { target.reset_memo_wise(:with_optional_positional_args, 1) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional keyword arguments" do
            expect { target.reset_memo_wise(:with_optional_keyword_args) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional keyword arguments provided" do
            expect { target.reset_memo_wise(:with_optional_keyword_args, a: 1) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional positional and keyword arguments" do
            expect { target.reset_memo_wise(:with_optional_positional_and_keyword_args) }.not_to raise_error
          end

          it "doesn't raise an error for methods with optional positional and keyword arguments provided" do
            expect { target.reset_memo_wise(:with_optional_positional_and_keyword_args, a: 1) }.not_to raise_error
          end
        end

        context "when the name of the method is not a symbol" do
          it { expect { target.reset_memo_wise("no_args") }.to raise_error(ArgumentError) }
        end

        context "when the method to reset memoization for is not memoized" do
          it { expect { target.reset_memo_wise(:unmemoized_method) { nil } }.to raise_error(ArgumentError) }
        end

        context "when the method to reset memoization for is not defined" do
          it { expect { target.reset_memo_wise(:not_defined) }.to raise_error(ArgumentError) }
        end
      end

      context "when method_name is *not* given (e.g. 'reset all' mode)" do
        before :each do
          # Memoize some method calls
          target.no_args
          target.with_positional_args(1, 2)
          target.with_positional_args(2, 3)
          target.with_keyword_args(a: 1, b: 2)
          target.with_keyword_args(a: 2, b: 3)
          target.special_chars?
          target.false_method
          target.nil_method

          # This is 'reset all' mode, as no method name is given
          target.reset_memo_wise
        end

        it "resets memoization for methods with no arguments" do
          expect(Array.new(4) { target.no_args }).to all eq("no_args")
          expect(target.no_args_counter).to eq(2)
        end

        it "resets memoization for methods with positional arguments" do
          expect(Array.new(4) { target.with_positional_args(1, 2) }).to all eq("with_positional_args: a=1, b=2")
          expect(Array.new(4) { target.with_positional_args(1, 3) }).to all eq("with_positional_args: a=1, b=3")

          # This should be executed twice for each set of arguments passed
          expect(target.with_positional_args_counter).to eq(4)
        end

        it "resets memoization for methods with keyword arguments" do
          expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).to all eq("with_keyword_args: a=1, b=2")
          expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).to all eq("with_keyword_args: a=2, b=3")

          # This should be executed twice for each set of arguments passed
          expect(target.with_keyword_args_counter).to eq(4)
        end

        it "resets memoization for methods with special characters in the name" do
          expect(Array.new(4) { target.special_chars? }).to all eq("special_chars?")
          expect(target.special_chars_counter).to eq(2)
        end

        it "resets memoization for methods set to false values" do
          expect(Array.new(4) { target.false_method }).to all eq(false)
          expect(target.false_method_counter).to eq(2)
        end

        it "resets memoization for methods set to nil values" do
          expect(Array.new(4) { target.nil_method }).to all eq(nil)
          expect(target.nil_method_counter).to eq(2)
        end
      end

      context "when method_name=nil and positional args given" do
        it { expect { target.reset_memo_wise(nil, 42) { nil } }.to raise_error(ArgumentError) }
      end

      context "when method_name=nil and keyword args given" do
        it { expect { target.reset_memo_wise(foo: 42) { nil } }.to raise_error(ArgumentError) }
      end
    end

    context "with instance methods" do
      include_context "with context for instance methods"

      # Use the instance as the target of "#preset_memo_wise shared examples"
      let(:target) { instance }

      it_behaves_like "#reset_memo_wise shared examples"

      context "when method_name is given" do
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
      end

      context "when method_name is *not* given (e.g. 'reset all' mode)" do
        it "does not reset memoization methods across instances" do
          instance2 = class_with_memo.new

          instance.no_args
          instance2.no_args

          instance.reset_memo_wise

          instance.no_args
          instance2.no_args

          expect(instance.no_args_counter).to eq(2)
          expect(instance2.no_args_counter).to eq(1)
        end
      end

      context "when method name is the same as a memoized class method" do
        let(:class_with_memo) do
          Class.new do
            prepend MemoWise

            def instance_one_arg_counter
              @instance_one_arg_counter || 0
            end

            def one_arg(a) # rubocop:disable Naming/MethodParameterName
              @instance_one_arg_counter = instance_one_arg_counter + 1
              "instance_one_arg: a=#{a}"
            end
            memo_wise :one_arg

            def self.class_one_arg_counter
              @class_one_arg_counter || 0
            end

            def self.one_arg(a) # rubocop:disable Naming/MethodParameterName
              @class_one_arg_counter = class_one_arg_counter + 1
              "class_one_arg: a=#{a}"
            end
            memo_wise self: :one_arg
          end
        end

        it "resets memoization independently" do
          instance = class_with_memo.new
          expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
          expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

          class_with_memo.reset_memo_wise(:one_arg)

          expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
          expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

          expect(instance.instance_one_arg_counter).to eq 1 # Never reset, so only incremented once.
          expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.

          instance.reset_memo_wise(:one_arg)

          expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
          expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

          expect(instance.instance_one_arg_counter).to eq 2 # Once initially and once after resetting.
          expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.
        end
      end
    end

    context "with class methods" do
      context "when defined with 'def self.'" do
        include_context "with context for class methods via 'def self.'"

        # Use the class as the target of "#reset_memo_wise shared examples"
        let(:target) { class_with_memo }

        it_behaves_like "#reset_memo_wise shared examples"

        context "when method name is the same as a memoized instance method" do
          let(:class_with_memo) do
            Class.new do
              prepend MemoWise

              def instance_one_arg_counter
                @instance_one_arg_counter || 0
              end

              def one_arg(a) # rubocop:disable Naming/MethodParameterName
                @instance_one_arg_counter = instance_one_arg_counter + 1
                "instance_one_arg: a=#{a}"
              end
              memo_wise :one_arg

              def self.class_one_arg_counter
                @class_one_arg_counter || 0
              end

              def self.one_arg(a) # rubocop:disable Naming/MethodParameterName
                @class_one_arg_counter = class_one_arg_counter + 1
                "class_one_arg: a=#{a}"
              end
              memo_wise self: :one_arg
            end
          end

          it "resets memoization independently" do
            instance = class_with_memo.new
            expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
            expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

            class_with_memo.reset_memo_wise(:one_arg)

            expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
            expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

            expect(instance.instance_one_arg_counter).to eq 1 # Never reset, so only incremented once.
            expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.

            instance.reset_memo_wise(:one_arg)

            expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
            expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

            expect(instance.instance_one_arg_counter).to eq 2 # Once initially and once after resetting.
            expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.
          end
        end
      end

      # These test cases would fail due to a JRuby bug
      # Skipping to make build pass until the bug is fixed
      # https://github.com/jruby/jruby/issues/6896
      unless RUBY_PLATFORM == "java"
        context "when defined with scope 'class << self'" do
          include_context "with context for class methods via scope 'class << self'"

          # Use the class as the target of "#reset_memo_wise shared examples"
          let(:target) { class_with_memo }

          it_behaves_like "#reset_memo_wise shared examples"

          context "when method name is the same as a memoized instance method" do
            let(:class_with_memo) do
              Class.new do
                prepend MemoWise

                def instance_one_arg_counter
                  @instance_one_arg_counter || 0
                end

                def one_arg(a) # rubocop:disable Naming/MethodParameterName
                  @instance_one_arg_counter = instance_one_arg_counter + 1
                  "instance_one_arg: a=#{a}"
                end
                memo_wise :one_arg

                class << self
                  prepend MemoWise

                  def class_one_arg_counter
                    @class_one_arg_counter || 0
                  end

                  def one_arg(a) # rubocop:disable Naming/MethodParameterName
                    @class_one_arg_counter = class_one_arg_counter + 1
                    "class_one_arg: a=#{a}"
                  end
                  memo_wise :one_arg
                end
              end
            end

            it "resets memoization independently" do
              instance = class_with_memo.new
              expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
              expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

              class_with_memo.reset_memo_wise(:one_arg)

              expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
              expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

              expect(instance.instance_one_arg_counter).to eq 1 # Never reset, so only incremented once.
              expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.

              instance.reset_memo_wise(:one_arg)

              expect(Array.new(4) { instance.one_arg(1) }).to all eq("instance_one_arg: a=1")
              expect(Array.new(4) { class_with_memo.one_arg(1) }).to all eq("class_one_arg: a=1")

              expect(instance.instance_one_arg_counter).to eq 2 # Once initially and once after resetting.
              expect(class_with_memo.class_one_arg_counter).to eq 2 # Once initially and once after resetting.
            end
          end
        end
      end
    end
  end
end

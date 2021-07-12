# frozen_string_literal: true

require "values"

RSpec.describe MemoWise do
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

    context "with module methods" do
      context "when defined with 'def self.'" do
        include_context "with context for module methods via 'def self.'"

        # Use the module as the target of "#memo_wise shared examples"
        let(:target) { module_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a module-level instance variable" do
          # NOTE: test implementation detail to ensure the inverse test is valid
          expect(module_with_memo.instance_variables).to include(:@_memo_wise)
        end

        context "when an invalid hash key is passed to .memo_wise" do
          let(:module_with_memo) do
            Module.new do
              prepend MemoWise

              def self.module_method; end
            end
          end

          it "raises an error when passing a key which is not `self:`" do
            expect { module_with_memo.send(:memo_wise, bad_key: :module_method) }.
              to raise_error(
                ArgumentError,
                "`:self` is the only key allowed in memo_wise"
              )
          end
        end
      end

      context "when defined with scope 'module << self'" do
        include_context "with context for module methods via scope "\
                        "'class << self'"

        # Use the module as the target of "#memo_wise shared examples"
        let(:target) { module_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a module-level instance variable" do
          # NOTE: this test ensure the inverse test above continues to be valid
          expect(module_with_memo.instance_variables).to include(:@_memo_wise)
        end
      end
    end

    context "with module mixed into other classes" do
      context "extended" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          let(:class_extending_module_with_memo) do
            Object.send(:remove_const, :ModuleWithMemo) if defined?(ModuleWithMemo)
            ModuleWithMemo = module_with_memo

            Class.new do
              extend ModuleWithMemo
            end
          end

          let(:target) { class_extending_module_with_memo }

          it_behaves_like "#memo_wise shared examples"
        end
      end
      context "included" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          let(:class_extending_module_with_memo) do
            Object.send(:remove_const, :ModuleWithMemo) if defined?(ModuleWithMemo)
            ModuleWithMemo = module_with_memo

            Class.new do
              include ModuleWithMemo
            end
          end
          let(:instance) { class_extending_module_with_memo.new }

          let(:target) { instance }

          it_behaves_like "#memo_wise shared examples"
        end
      end
      context "prepended" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          let(:class_extending_module_with_memo) do
            Object.send(:remove_const, :ModuleWithMemo) if defined?(ModuleWithMemo)
            ModuleWithMemo = module_with_memo

            Class.new do
              prepend ModuleWithMemo
            end
          end
          let(:instance) { class_extending_module_with_memo.new }

          let(:target) { instance }

          it_behaves_like "#memo_wise shared examples"
        end
      end
    end
  end
end

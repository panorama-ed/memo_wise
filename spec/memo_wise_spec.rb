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
        expect(Array.new(4) { target.with_one_positional_arg(1) }).to all eq("with_one_positional_arg: a=1")
        expect(Array.new(4) { target.with_one_positional_arg(2) }).to all eq("with_one_positional_arg: a=2")

        # This should be executed once for each set of arguments passed
        expect(target.with_one_positional_arg_counter).to eq(2)
      end

      it "memoizes methods with positional arguments" do
        expect(Array.new(4) { target.with_positional_args(1, 2) }).to all eq("with_positional_args: a=1, b=2")
        expect(Array.new(4) { target.with_positional_args(1, 3) }).to all eq("with_positional_args: a=1, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_args_counter).to eq(2)
      end

      it "memoizes methods with positional and splat arguments" do
        expect(Array.new(4) { target.with_positional_and_splat_args(1, 2, 3) }).
          to all eq("with_positional_and_splat_args: a=1, args=[2, 3]")

        expect(Array.new(4) { target.with_positional_and_splat_args(1, 3, 4) }).
          to all eq("with_positional_and_splat_args: a=1, args=[3, 4]")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_and_splat_args_counter).to eq(2)
      end

      it "memoizes methods with one keyword argument" do
        expect(Array.new(4) { target.with_one_keyword_arg(a: 1) }).to all eq("with_one_keyword_arg: a=1")
        expect(Array.new(4) { target.with_one_keyword_arg(a: 2) }).to all eq("with_one_keyword_arg: a=2")

        # This should be executed once for each set of arguments passed
        expect(target.with_one_keyword_arg_counter).to eq(2)
      end

      it "memoizes methods with keyword arguments" do
        expect(Array.new(4) { target.with_keyword_args(a: 1, b: 2) }).to all eq("with_keyword_args: a=1, b=2")
        expect(Array.new(4) { target.with_keyword_args(a: 2, b: 3) }).to all eq("with_keyword_args: a=2, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_keyword_args_counter).to eq(2)
      end

      it "memoizes methods with keyword and double-splat arguments" do
        expect(Array.new(4) { target.with_keyword_and_double_splat_args(a: 1, b: 2, c: 3) }).
          to all eq("with_keyword_and_double_splat_args: a=1, kwargs=#{{ b: 2, c: 3 }}") # rubocop:disable Lint/LiteralInInterpolation

        expect(Array.new(4) { target.with_keyword_and_double_splat_args(a: 1, b: 2, c: 4) }).
          to all eq("with_keyword_and_double_splat_args: a=1, kwargs=#{{ b: 2, c: 4 }}") # rubocop:disable Lint/LiteralInInterpolation

        # This should be executed once for each set of arguments passed
        expect(target.with_keyword_and_double_splat_args_counter).to eq(2)
      end

      it "memoizes methods with positional and keyword arguments" do
        expect(Array.new(4) { target.with_positional_and_keyword_args(1, b: 2) }).
          to all eq("with_positional_and_keyword_args: a=1, b=2")

        expect(Array.new(4) { target.with_positional_and_keyword_args(2, b: 3) }).
          to all eq("with_positional_and_keyword_args: a=2, b=3")

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_and_keyword_args_counter).to eq(2)
      end

      it "memoizes methods with positional, splat, keyword, and double-splat arguments" do
        expect(Array.new(4) { target.with_positional_splat_keyword_and_double_splat_args(1, 2, 3, b: 4, c: 5, d: 6) }).
          to all eq("with_positional_splat_keyword_and_double_splat_args: a=1, args=[2, 3] b=4 kwargs=#{{ c: 5, d: 6 }}") # rubocop:disable Layout/LineLength, Lint/LiteralInInterpolation

        expect(Array.new(4) { target.with_positional_splat_keyword_and_double_splat_args(1, 2, b: 4, c: 5) }).
          to all eq("with_positional_splat_keyword_and_double_splat_args: a=1, args=[2] b=4 kwargs=#{{ c: 5 }}") # rubocop:disable Lint/LiteralInInterpolation

        # This should be executed once for each set of arguments passed
        expect(target.with_positional_splat_keyword_and_double_splat_args_counter).to eq(2)
      end

      it "memoizes methods with special characters in the name" do
        expect(Array.new(4) { target.special_chars? }).to all eq("special_chars?")
        expect(target.special_chars_counter).to eq(1)
      end

      it "memoizes methods set to false values" do
        expect(Array.new(4) { target.false_method }).to all be(false)
        expect(target.false_method_counter).to eq(1)
      end

      it "memoizes methods set to nil values" do
        expect(Array.new(4) { target.nil_method }).to all be_nil
        expect(target.nil_method_counter).to eq(1)
      end

      context "with private methods" do
        it "keeps private methods private" do
          expect(target.private_methods).to include(:private_memowise_method)
        end

        it "memoizes private methods" do
          expect(Array.new(4) { target.send(:private_memowise_method) }).to all eq("private_memowise_method")
          expect(target.private_memowise_method_counter).to eq(1)
        end
      end

      context "with public methods" do
        it "keeps public methods public" do
          expect(target.public_methods).to include(:public_memowise_method)
        end

        it "memoizes public methods" do
          expect(Array.new(4) { target.public_memowise_method }).to all eq("public_memowise_method")
          expect(target.public_memowise_method_counter).to eq(1)
        end
      end

      it "memoizes methods with proc arguments" do
        proc_param = proc { true }
        expect(Array.new(4) { target.proc_method(proc_param) }).to all be(true)

        expect(target.proc_method_counter).to eq(1)
      end

      it "does not memoize methods with implicit block arguments" do
        expect { target.implicit_block_method }.to raise_error(LocalJumpError)
      end

      it "does not memoize methods with explicit block arguments" do
        expect { target.explicit_block_method { nil } }.to raise_error(LocalJumpError)
      end
    end

    shared_examples "handles memoized/non-memoized methods with the same name at different scopes" do
      context "with non-memoized method with same name as memoized method" do
        context "when methods have no arguments" do
          it "does not memoize the non-memoized method" do
            # Confirm the memoized method works correctly first.
            expect(Array.new(4) { memoized.no_args }).to all eq("no_args")
            expect(memoized.no_args_counter).to eq(1)

            # Now confirm our non-memoized method is not memoized.
            expect(Array.new(4) { non_memoized.no_args }).to all eq("#{non_memoized_name}_no_args")
            expect(non_memoized.send(:"#{non_memoized_name}_no_args_counter")).to eq(4)
          end
        end

        context "when methods have one positional argument" do
          it "does not memoize the non-memoized method" do
            # Confirm the memoized method works correctly first.
            expect(Array.new(4) { memoized.with_one_positional_arg(1) }).to all eq("with_one_positional_arg: a=1")
            expect(memoized.with_one_positional_arg_counter).to eq(1)

            # Now confirm our non-memoized method is not memoized.
            expect(Array.new(4) { non_memoized.with_one_positional_arg(1) }).
              to all eq("#{non_memoized_name}_with_one_positional_arg: a=1")

            expect(non_memoized.send(:"#{non_memoized_name}_one_positional_arg_counter")).to eq(4)
          end
        end

        context "when methods have multiple positional arguments" do
          it "does not memoize the non-memoized method" do
            # Confirm the memoized method works correctly first.
            expect(Array.new(4) { memoized.with_positional_args(1, 2) }).to all eq("with_positional_args: a=1, b=2")
            expect(memoized.with_positional_args_counter).to eq(1)

            # Now confirm our non-memoized method is not memoized.
            expect(Array.new(4) { non_memoized.with_positional_args(1, 2) }).
              to all eq("#{non_memoized_name}_with_positional_args: a=1, b=2")

            expect(non_memoized.send(:"#{non_memoized_name}_positional_args_counter")).to eq(4)
          end
        end
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
          expect(target.protected_methods).to include(:protected_memowise_method)
        end

        it "memoizes protected methods" do
          expect(Array.new(4) { target.send(:protected_memowise_method) }).to all eq("protected_memowise_method")
          expect(target.protected_memowise_method_counter).to eq(1)
        end
      end

      context "when memo_wise has *not* been called on a *class* method" do
        it "does *not* create class-level instance variable" do
          expect(class_with_memo.instance_variables).not_to include(:@_memo_wise)
        end
      end

      # This test nondeterministically fails in JRuby with the following error:
      # NoMethodError:
      #   super: no superclass method `allocate' for #<Class:0xacc6a69>
      unless RUBY_PLATFORM == "java"
        context "when instances are created with Class#allocate" do
          let(:instance) { class_with_memo.allocate }

          it "memoizes correctly" do
            expect(Array.new(4) { instance.no_args }).to all eq("no_args")
            expect(instance.no_args_counter).to eq(1)
          end
        end
      end

      context "when the name of the method to memoize is not a symbol" do
        let(:class_with_memo) do
          super().tap { |klass| klass.memo_wise "no_args" }
        end

        it { expect { instance }.to raise_error(ArgumentError) }
      end

      it_behaves_like "handles memoized/non-memoized methods with the same name at different scopes" do
        let(:memoized) { instance }
        let(:non_memoized) { class_with_memo }
        let(:non_memoized_name) { :class }
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

      context "when the class has a child class" do
        let(:child_class) do
          Class.new(class_with_memo) do
            def child_method_counter
              @child_method_counter || 0
            end

            def child_method
              @child_method_counter = child_method_counter + 1
              "child_method"
            end
          end
        end

        let(:instance) { child_class.new }

        it "memoizes the parent methods" do
          expect(Array.new(4) { instance.no_args }).to all eq("no_args")
          expect(instance.no_args_counter).to eq(1)
          expect(Array.new(4) { instance.child_method }).to all eq("child_method")
          expect(instance.child_method_counter).to eq(4)
        end

        context "when the child class also memoizes methods" do
          before :each do
            child_class.prepend described_class
            child_class.memo_wise :child_method
          end

          it "memoizes the parent and child methods separately" do
            expect(Array.new(4) { instance.no_args }).to all eq("no_args")
            expect(instance.no_args_counter).to eq(1)
            expect(Array.new(4) { instance.child_method }).to all eq("child_method")
            expect(instance.child_method_counter).to eq(1)
          end
        end
      end

      context "when the class inherits memoization from multiple modules" do
        let(:module1) do
          Module.new do
            prepend MemoWise

            def module1_method_counter
              @module1_method_counter || 0 # rubocop:disable RSpec/InstanceVariable
            end

            def module1_method
              @module1_method_counter = module1_method_counter + 1
              "module1_method"
            end
            memo_wise :module1_method
          end
        end

        let(:module2) do
          Module.new do
            prepend MemoWise

            def module2_method_counter
              @module2_method_counter || 0 # rubocop:disable RSpec/InstanceVariable
            end

            def module2_method
              @module2_method_counter = module2_method_counter + 1
              "module2_method"
            end
            memo_wise :module2_method
          end
        end

        let(:klass) do
          Class.new do
            include Module1, Module2
          end
        end

        let(:klass_with_initializer) do
          Class.new do
            include Module1
            def initialize(...); end
          end
        end

        let(:module_with_initializer) do
          Module.new do
            include Module1
            def initialize(...); end
          end
        end

        let(:klass_with_module_with_initializer) do
          Class.new do
            include Module3
          end
        end

        let(:instance) { klass.new }

        before(:each) do
          stub_const("Module1", module1)
          stub_const("Module2", module2)
          stub_const("Module3", module_with_initializer)
        end

        it "memoizes inherited methods separately" do
          expect(Array.new(4) { instance.module1_method }).to all eq("module1_method")
          expect(instance.module1_method_counter).to eq(1)
          expect(Array.new(4) { instance.module2_method }).to all eq("module2_method")
          expect(instance.module2_method_counter).to eq(1)
        end

        # These tests require this behavior from Ruby 3.1: https://bugs.ruby-lang.org/issues/17423
        # TruffleRuby decided not to implement that change in their MRI 3.1-
        # equivalent release; search for "Module#prepend" here: https://github.com/oracle/truffleruby/issues/2733
        # If/when they implement it, this conditional may be removed.
        unless RUBY_ENGINE == "truffleruby"
          it "can memoize klass with initializer" do
            instance = klass_with_initializer.new(true)
            expect { instance.module1_method }.not_to raise_error

            expect(Array.new(4) { instance.module1_method }).to all eq("module1_method")
            expect(instance.module1_method_counter).to eq(1)
          end

          it "can memoize klass with module with initializer" do
            instance = klass_with_module_with_initializer.new(true)
            expect { instance.module1_method }.not_to raise_error

            expect(Array.new(4) { instance.module1_method }).to all eq("module1_method")
            expect(instance.module1_method_counter).to eq(1)
          end

          it "can reset klass with initializer" do
            instance = klass_with_initializer.new(true)
            expect { instance.reset_memo_wise }.not_to raise_error
          end

          it "can reset klass with module with initializer" do
            instance = klass_with_module_with_initializer.new(true)
            expect { instance.reset_memo_wise }.not_to raise_error
          end
        end
      end

      context "when the class, its superclass, and its module all memoize methods" do
        let(:parent_class) do
          Class.new do
            prepend MemoWise

            def parent_class_method_counter
              @parent_class_method_counter || 0
            end

            def parent_class_method
              @parent_class_method_counter = parent_class_method_counter + 1
              "parent_class_method"
            end
            memo_wise :parent_class_method
          end
        end

        let(:module1) do
          Module.new do
            prepend MemoWise

            def module1_method_counter
              @module1_method_counter || 0 # rubocop:disable RSpec/InstanceVariable
            end

            def module1_method
              @module1_method_counter = module1_method_counter + 1
              "module1_method"
            end
            memo_wise :module1_method
          end
        end

        let(:child_class) do
          Class.new(parent_class) do
            include Module1

            def child_class_method_counter
              @child_class_method_counter || 0
            end

            def child_class_method
              @child_class_method_counter = child_class_method_counter + 1
              "child_class_method"
            end
            memo_wise :child_class_method
          end
        end

        let(:instance) { child_class.new }

        before(:each) do
          stub_const("Module1", module1)
        end

        it "memoizes inherited methods separately" do
          expect(Array.new(4) { instance.parent_class_method }).to all eq("parent_class_method")
          expect(instance.parent_class_method_counter).to eq(1)
          expect(Array.new(4) { instance.module1_method }).to all eq("module1_method")
          expect(instance.module1_method_counter).to eq(1)
          expect(Array.new(4) { instance.child_class_method }).to all eq("child_class_method")
          expect(instance.child_class_method_counter).to eq(1)
        end
      end

      context "when a module prepends MemoWise and defines `.included`" do
        let(:module_to_include) do
          Module.new do
            prepend MemoWise

            def self.included(base)
              base.class_eval do
                @internal_state = true
              end
            end

            def method1
              self.class.internal_state
            end
            memo_wise :method1
          end
        end

        let(:klass) do
          Class.new do
            include ModuleToInclude

            def self.internal_state
              @internal_state ||= false
            end
          end
        end

        let(:instance) { klass.new }

        before(:each) { stub_const("ModuleToInclude", module_to_include) }

        it "calls module `.included` method" do
          expect(instance.send(:method1)).to be true
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

        it_behaves_like "handles memoized/non-memoized methods with the same name at different scopes" do
          let(:memoized) { class_with_memo }
          let(:non_memoized) { class_with_memo.new }
          let(:non_memoized_name) { :instance }
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
              to raise_error(ArgumentError, "`:self` is the only key allowed in memo_wise")
          end
        end

        context "when the class has a child class" do
          let(:child_class) do
            Class.new(class_with_memo) do
              def self.child_method_counter
                @child_method_counter || 0
              end

              def self.child_method
                @child_method_counter = child_method_counter + 1
                "child_method"
              end
            end
          end

          it "memoizes the parent methods" do
            expect(Array.new(4) { child_class.no_args }).to all eq("no_args")
            expect(child_class.no_args_counter).to eq(1)
            expect(Array.new(4) { child_class.child_method }).to all eq("child_method")
            expect(child_class.child_method_counter).to eq(4)
          end

          context "when the child class also memoizes methods" do
            before :each do
              child_class.prepend described_class
              child_class.memo_wise self: :child_method
            end

            it "memoizes the parent and child methods separately" do
              expect(Array.new(4) { child_class.no_args }).to all eq("no_args")
              expect(child_class.no_args_counter).to eq(1)
              expect(Array.new(4) { child_class.child_method }).to all eq("child_method")
              expect(child_class.child_method_counter).to eq(1)
            end
          end
        end
      end

      context "when defined with scope 'class << self'" do
        include_context "with context for class methods via scope 'class << self'"

        # Use the class as the target of "#memo_wise shared examples"
        let(:target) { class_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a class-level instance variable" do
          # NOTE: this test ensure the inverse test above continues to be valid
          expect(class_with_memo.instance_variables).to include(:@_memo_wise)
        end

        it_behaves_like "handles memoized/non-memoized methods with the same name at different scopes" do
          let(:memoized) { class_with_memo }
          let(:non_memoized) { class_with_memo.new }
          let(:non_memoized_name) { :instance }
        end

        context "when the class has a child class" do
          let(:child_class) do
            Class.new(class_with_memo) do
              class << self
                def child_method_counter
                  @child_method_counter || 0
                end

                def child_method
                  @child_method_counter = child_method_counter + 1
                  "child_method"
                end
              end
            end
          end

          it "memoizes the parent methods" do
            expect(Array.new(4) { child_class.no_args }).to all eq("no_args")
            expect(child_class.no_args_counter).to eq(1)
            expect(Array.new(4) { child_class.child_method }).to all eq("child_method")
            expect(child_class.child_method_counter).to eq(4)
          end

          context "when the child class also memoizes methods" do
            let(:child_class) do
              Class.new(class_with_memo) do
                class << self
                  prepend MemoWise

                  def child_method_counter
                    @child_method_counter || 0
                  end

                  def child_method
                    @child_method_counter = child_method_counter + 1
                    "child_method"
                  end
                  memo_wise :child_method
                end
              end
            end

            it "memoizes the parent and child methods separately" do
              expect(Array.new(4) { child_class.no_args }).to all eq("no_args")
              expect(child_class.no_args_counter).to eq(1)
              expect(Array.new(4) { child_class.child_method }).to all eq("child_method")
              expect(child_class.child_method_counter).to eq(1)
            end
          end
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
              to raise_error(ArgumentError, "`:self` is the only key allowed in memo_wise")
          end
        end
      end

      context "when defined with scope 'class << self'" do
        include_context "with context for module methods via scope 'class << self'"

        # Use the module as the target of "#memo_wise shared examples"
        let(:target) { module_with_memo }

        it_behaves_like "#memo_wise shared examples"

        it "creates a module-level instance variable" do
          # NOTE: this test ensure the inverse test above continues to be valid
          expect(module_with_memo.instance_variables).to include(:@_memo_wise)
        end
      end
    end

    context "when a class inherits from a parent class whose extended module memoizes methods" do
      let(:parent_class) do
        Class.new do
          extend Module1
        end
      end

      let(:module1) do
        Module.new do
          prepend MemoWise

          def module1_method_counter
            @module1_method_counter || 0 # rubocop:disable RSpec/InstanceVariable
          end

          def module1_method
            @module1_method_counter = module1_method_counter + 1
            Random.rand
          end
          memo_wise :module1_method
        end
      end

      let(:child_class) do
        Class.new(parent_class)
      end

      before(:each) do
        stub_const("Module1", module1)
      end

      it "memoizes inherited methods separately" do
        child_class_values = Array.new(4) { child_class.module1_method }.uniq
        parent_class_values = Array.new(4) { parent_class.module1_method }.uniq

        expect(child_class_values.size).to eq(1)
        expect(child_class.module1_method_counter).to eq(1)
        expect(parent_class_values.size).to eq(1)
        expect(parent_class.module1_method_counter).to eq(1)
        expect(child_class_values).not_to eq parent_class_values
      end
    end

    context "when a class inherits from a parent class where memo_wise is defined" do
      include_context "with context for inherited class instance"

      let(:target) { instance }

      it_behaves_like "#memo_wise shared examples"
    end

    context "with module mixed into other classes" do
      context "when extended" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          before(:each) { stub_const("ModuleWithMemo", module_with_memo) }

          let(:class_extending_module_with_memo) do
            Class.new do
              extend ModuleWithMemo
            end
          end

          let(:target) { class_extending_module_with_memo }

          it_behaves_like "#memo_wise shared examples"
        end

        context "when 1 module extended by 2 classes" do
          let(:module_with_memo) do
            Module.new do
              prepend MemoWise

              def test_method
                Random.rand
              end
              memo_wise :test_method
            end
          end
          let(:class_a_extending_module_with_memo) do
            Class.new do
              extend ModuleWithMemo
            end
          end
          let(:class_b_extending_module_with_memo) do
            Class.new do
              extend ModuleWithMemo
            end
          end

          before(:each) do
            stub_const("ModuleWithMemo", module_with_memo)
          end

          it "memoizes each extended class separately" do
            aggregate_failures do
              expect(class_a_extending_module_with_memo.test_method). # rubocop:disable RSpec/IdenticalEqualityAssertion
                to eq(class_a_extending_module_with_memo.test_method)
              expect(class_b_extending_module_with_memo.test_method). # rubocop:disable RSpec/IdenticalEqualityAssertion
                to eq(class_b_extending_module_with_memo.test_method)
              expect(class_a_extending_module_with_memo.test_method).
                to_not eq(class_b_extending_module_with_memo.test_method)
            end
          end
        end
      end

      context "when included" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          before(:each) do
            stub_const("ModuleWithMemo", module_with_memo)
          end

          let(:class_including_module_with_memo) do
            Class.new do
              include ModuleWithMemo
            end
          end
          let(:instance) { class_including_module_with_memo.new }

          let(:target) { instance }

          it_behaves_like "#memo_wise shared examples"

          it_behaves_like "handles memoized/non-memoized methods with the same name at different scopes" do
            let(:memoized) { instance }
            let(:non_memoized) { module_with_memo }
            let(:non_memoized_name) { :module }
          end
        end

        context "when defined with 'def self.' and 'def'" do
          let(:module_with_memo) do
            Module.new do
              prepend MemoWise

              def self.test_method
                Random.rand
              end
              memo_wise self: :test_method

              def test_method
                Random.rand
              end
              memo_wise :test_method
            end
          end
          let(:class_including_module_with_memo) do
            Class.new do
              include ModuleWithMemo
            end
          end
          let(:instance) { class_including_module_with_memo.new }

          before(:each) do
            stub_const("ModuleWithMemo", module_with_memo)
          end

          it "memoizes instance and singleton methods separately" do
            aggregate_failures do
              expect(instance.test_method).to eq(instance.test_method) # rubocop:disable RSpec/IdenticalEqualityAssertion
              expect(module_with_memo.test_method).to eq(module_with_memo.test_method) # rubocop:disable RSpec/IdenticalEqualityAssertion
              expect(instance.test_method).to_not eq(module_with_memo.test_method)
            end
          end
        end
      end

      context "when prepended" do
        context "when defined with 'def'" do
          include_context "with context for module methods via normal scope"

          before(:each) do
            stub_const("ModuleWithMemo", module_with_memo)
          end

          let(:class_prepending_module_with_memo) do
            Class.new do
              prepend ModuleWithMemo
            end
          end
          let(:instance) { class_prepending_module_with_memo.new }

          let(:target) { instance }

          it_behaves_like "#memo_wise shared examples"

          it_behaves_like "handles memoized/non-memoized methods with the same name at different scopes" do
            let(:memoized) { instance }
            let(:non_memoized) { module_with_memo }
            let(:non_memoized_name) { :module }
          end
        end
      end
    end

    context "with module defined self.extended" do
      let(:module_with_memo) do
        Module.new do
          prepend MemoWise

          def self.extended(base)
            base.instance_variable_set(:@extended_called, true)
          end

          def no_args
            @no_args_counter = no_args_counter + 1
          end
          memo_wise :no_args

          def no_args_counter
            @no_args_counter ||= 0
          end
        end
      end

      it "calls defined self.extended" do
        klass = Class.new
        instance = klass.new
        instance.extend(module_with_memo)

        expect(instance.instance_variable_get(:@extended_called)).to be(true)

        expect(Array.new(4) { instance.no_args }).to all(eq(1))
        expect(instance.no_args_counter).to eq(1)
      end
    end

    context "with target defined self.inherited" do
      context "when target is class" do
        let(:klass) do
          Class.new do
            prepend MemoWise

            def self.inherited(subclass)
              super
              subclass.instance_variable_set(:@inherited_called, true)
            end

            def no_args
              @no_args_counter = no_args_counter + 1
            end
            memo_wise :no_args

            def no_args_counter
              @no_args_counter ||= 0
            end
          end
        end

        it "calls defined self.inherited" do
          inherited = Class.new(klass)
          expect(inherited.instance_variable_get(:@inherited_called)).to be(true)

          instance = inherited.new
          expect(Array.new(4) { instance.no_args }).to all(eq(1))
          expect(instance.no_args_counter).to eq(1)
        end

        it "doesn't define #inherited" do
          expect(klass).to respond_to(:inherited)
          expect(klass.new).to_not respond_to(:inherited)
        end
      end

      context "when target is singleton class" do
        let(:klass) do
          Class.new do
            class << self
              prepend MemoWise

              def inherited(subclass)
                super
                subclass.instance_variable_set(:@inherited_called, true)
              end

              def no_args
                @no_args_counter = no_args_counter + 1
              end
              memo_wise :no_args

              def no_args_counter
                @no_args_counter ||= 0
              end
            end
          end
        end

        it "calls defined self.inherited" do
          inherited = Class.new(klass)
          expect(inherited.instance_variable_get(:@inherited_called)).to be(true)

          expect(Array.new(4) { inherited.no_args }).to all(eq(1))
          expect(inherited.no_args_counter).to eq(1)
        end

        it "doesn't define #inherited" do
          expect(klass).to respond_to(:inherited)
          expect(klass.new).to_not respond_to(:inherited)
        end
      end

      context "when target is module" do
        let(:klass) do
          mod = Module.new do
            prepend MemoWise

            def inherited(subclass)
              super
              subclass.instance_variable_set(:@inherited_called, true)
            end

            def no_args
              @no_args_counter = no_args_counter + 1
            end
            memo_wise :no_args

            def no_args_counter
              @no_args_counter ||= 0
            end
          end

          klass = Class.new
          klass.extend(mod)
          klass
        end

        it "calls defined self.inherited" do
          inherited = Class.new(klass)
          expect(inherited.instance_variable_get(:@inherited_called)).to be(true)

          expect(Array.new(4) { inherited.no_args }).to all(eq(1))
          expect(inherited.no_args_counter).to eq(1)
        end

        it "doesn't define #inherited" do
          expect(klass).to respond_to(:inherited)
          expect(klass.new).to_not respond_to(:inherited)
        end
      end
    end
  end
end

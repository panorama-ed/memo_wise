# frozen_string_literal: true

RSpec.describe MemoWise do
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

      context "with one positional arg that is an array" do
        let(:expected_counter) { overriding ? 2 : 0 }

        before(:each) do
          if overriding
            target.with_one_positional_arg([1])
            target.with_one_positional_arg([2])
          end
        end

        it "presets memoization" do
          target.preset_memo_wise(:with_one_positional_arg, [1]) { "preset1" }
          target.preset_memo_wise(:with_one_positional_arg, [2]) { "preset2" }

          expect(Array.new(4) { target.with_one_positional_arg([1]) }).
            to all eq("preset1")

          expect(Array.new(4) { target.with_one_positional_arg([2]) }).
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
        include_context "with context for class methods via scope 'class << self'"

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
end

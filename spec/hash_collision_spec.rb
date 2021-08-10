# frozen_string_literal: true

RSpec.describe MemoWise do
  context "when #hash of arguments collisions" do
    let(:instance) { class_with_memo.new }

    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        def return_given_args(a, b)
          [a, b]
        end
        memo_wise :return_given_args
      end
    end

    context "when override #hash to force collision but not equal" do
      let(:klass) do
        Struct.new(:str, :hash)
      end

      let(:args_1) { [klass.new("one", 42), klass.new("one", 42)] }
      let(:args_2) { [klass.new("two", 42), klass.new("two", 42)] }

      it "returns separately memoized results for each call" do
        expect(instance.return_given_args(*args_1)).to eq(args_1)
        expect(instance.return_given_args(*args_2)).to eq(args_2)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe "hash collisions" do # rubocop:disable RSpec/DescribeClass
  context "when #hash of arguments collisions" do
    let(:instance) { class_with_memo.new }

    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        def return_given_args(a, b) # rubocop:disable Naming/MethodParameterName
          [a, b]
        end
        memo_wise :return_given_args
      end
    end

    context "when override #hash to force collision but not equal" do
      let(:klass) do
        Struct.new(:str, :hash) # rubocop:disable Lint/StructNewOverride
      end

      let(:args1) { [klass.new("one", 42), klass.new("one", 42)] }
      let(:args2) { [klass.new("two", 42), klass.new("two", 42)] }

      it "returns separately memoized results for each call" do
        expect(instance.return_given_args(*args1)).to eq(args1)
        expect(instance.return_given_args(*args2)).to eq(args2)
      end
    end
  end
end

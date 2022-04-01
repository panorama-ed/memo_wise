# frozen_string_literal: true

RSpec.describe "prepending initializer" do # rubocop:disable RSpec/DescribeClass
  context "when the class's initializer takes arguments" do
    context "when it only takes positional arguments" do
      let(:class_with_memo) do
        Class.new do
          extend MemoWise

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
          extend MemoWise

          def initialize(kwarg:); end
        end
      end

      it "does not raise an error when initializing the class" do
        expect { class_with_memo.new(kwarg: :kw) }.to_not raise_error
      end
    end

    context "when it takes both positional and keyword arguments" do
      let(:class_with_memo) do
        Class.new do
          extend MemoWise

          def initialize(arg, kwarg:); end
        end
      end

      it "does not raise an error when initializing the class" do
        expect { class_with_memo.new(:pos, kwarg: :kw) }.to_not raise_error
      end
    end

    context "when the method takes positional arguments, keyword arguments, and a block" do
      let(:class_with_memo) do
        Class.new do
          extend MemoWise

          def initialize(arg, kwarg:, &blk)
            blk.call(arg, kwarg) # rubocop:disable Performance/RedundantBlockCall
          end
        end
      end

      it "does not raise an error when initializing the class" do
        expect { class_with_memo.new(:pos, kwarg: :kw) { true } }.to_not raise_error
      end
    end
  end
end

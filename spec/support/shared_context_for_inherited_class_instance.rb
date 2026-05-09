# frozen_string_literal: true

RSpec.shared_context "with context for inherited class instance" do
  let(:parent_class) do
    Class.new do
      prepend MemoWise
    end
  end

  let(:inherited_class_with_memo) do
    Class.new(parent_class) do
      def initialize; end

      DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
        target: self,
        via: :instance
      )
    end
  end

  let(:instance) { inherited_class_with_memo.new }
end

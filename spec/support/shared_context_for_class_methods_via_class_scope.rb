# frozen_string_literal: true

RSpec.shared_context "with context for class methods via scope 'class << self'" do # rubocop:disable Layout/LineLength
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

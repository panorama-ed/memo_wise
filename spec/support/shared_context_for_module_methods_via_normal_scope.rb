# frozen_string_literal: true

RSpec.shared_context "with context for module methods via normal scope" do
  let(:module_with_memo) do
    Module.new do
      prepend MemoWise

      DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
        target: self,
        via: :instance
      )
    end
  end
end

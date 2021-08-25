# frozen_string_literal: true

RSpec.shared_context "with context for module methods via scope 'class << self'" do
  # NOTE: This use of `before(:all)` is a performance optimization that shaves
  # minutes off of our test suite, especially in older versions of Ruby.
  before(:all) do
    @_module_with_memo = Module.new do
      class << self
        prepend MemoWise

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :instance
        )
      end
    end
  end

  let(:module_with_memo) { @_module_with_memo } # rubocop:disable RSpec/InstanceVariable
end

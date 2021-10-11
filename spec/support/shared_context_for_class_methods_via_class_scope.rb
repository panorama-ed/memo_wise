# frozen_string_literal: true

RSpec.shared_context "with context for class methods via scope 'class << self'" do
  # NOTE: This use of `before(:all)` is a performance optimization that shaves
  # minutes off of our test suite, especially in older versions of Ruby.
  before(:all) do
    @_class_with_memo = Class.new do
      class << self
        extend MemoWise

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :instance
        )
      end
    end
  end

  let(:class_with_memo) do
    # Because we now have shared state between tests, we need to ensure that we
    # reset memo_wise, as well as any test state, for each individual test.
    # rubocop:disable RSpec/InstanceVariable
    @_class_with_memo.reset_memo_wise
    @_class_with_memo.instance_variables.each do |var|
      # reset test method counters from DefineMethodsForTestingMemoWise
      @_class_with_memo.instance_variable_set(var, 0) if @_class_with_memo.instance_variable_get(var).is_a?(Integer)
    end
    @_class_with_memo
    # rubocop:enable RSpec/InstanceVariable
  end
end

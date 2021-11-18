# frozen_string_literal: true

RSpec.describe "thread safety" do # rubocop:disable RSpec/DescribeClass
  context "when two threads accessing unmemoized zero-args method" do
    let(:thread_return_values) do
      any_nils = ->(a) { a.any?(&:nil?) }

      check_repeatedly(condition_proc: any_nils) do
        instance = class_with_memo.new
        threads = Array.new(2) { Thread.new { instance.first_thread_id } }
        threads.map(&:value)
      end
    end

    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        def first_thread_id
          Thread.pass # trigger a race condition even on MRI
          Thread.current.object_id
        end
        memo_wise :first_thread_id
      end
    end

    # Tip of the hat to @jeremyevans for finding and fixing a race condition
    # which caused accidental `nil` values to be returned under contended calls
    # to unmemoized zero-args methods.
    #   * See https://github.com/panorama-ed/memo_wise/pull/224
    it "does not return accidental nil value to either thread" do
      expect(thread_return_values).not_to include(nil)
    end
  end
end

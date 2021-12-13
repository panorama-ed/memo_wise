# frozen_string_literal: true

RSpec.describe "thread safety" do # rubocop:disable RSpec/DescribeClass
  context "when two threads accessing unmemoized zero-args method" do
    let(:thread_return_values) do
      check_repeatedly(condition_proc: condition_to_check) do
        @instance = class_with_memo.new
        threads = Array.new(2) { Thread.new { @instance.current_thread_id } } # rubocop:disable RSpec/InstanceVariable
        threads.map(&:value)
      end
    end

    # Using `def` here makes race conditions far more likely than `let`.
    def class_with_memo
      Class.new do
        prepend MemoWise

        def current_thread_id
          Thread.pass              # trigger a race condition even on MRI
          Thread.current.object_id # return different values in each thread
        end
        memo_wise :current_thread_id
      end
    end

    # Tip of the hat to @jeremyevans for finding and fixing a race condition
    # which caused accidental `nil` values to be returned under contended calls
    # to unmemoized zero-args methods.
    #   * See https://github.com/panorama-ed/memo_wise/pull/224
    context "when checking condition: are nil values accidentally returned?" do
      let(:condition_to_check) do
        ->(values) { values.any?(&:nil?) }
      end

      it "does not return accidental nil value to either thread" do
        expect(thread_return_values).not_to include(nil)
      end
    end

    # When memoizing non-deterministic methods, MemoWise does not impose any
    # additional guarantees other than:
    #   * Return values are one of the valid returns from the original method
    #   * Return values may differ between threads under contended calls
    #   * One of those return values will be memoized and returned thereafter
    context "when checking condition: are different values returned?" do
      let(:condition_to_check) do
        ->(values) { values.uniq.size > 1 }
      end

      let(:after_memoization_thread_return_values) do
        thread_return_values # Ensure threads have already executed

        check_repeatedly(condition_proc: condition_to_check) do
          threads = Array.new(2) { Thread.new { @instance.current_thread_id } } # rubocop:disable RSpec/InstanceVariable
          threads.map(&:value)
        end
      end

      # NOTE: Disabled on TruffleRuby in CI, because it takes multiple seconds
      # to observe the different values returned to multiple threads, and errors
      # out in some cases when that does happen.
      unless RUBY_ENGINE == "truffleruby" && ENV["CI"] == "true"
        it "returns different values to each thread, and memoizes one of them" do
          # Before memoization: expect to observe threads return different values
          expect(thread_return_values.uniq.size).to be > 1

          # After memoization: expect to observe only a single value...
          expect(after_memoization_thread_return_values.uniq.size).to be 1

          # ...and that single value is one the values returned originally
          expect(thread_return_values).
            to include(after_memoization_thread_return_values.first)
        end
      end
    end
  end
end

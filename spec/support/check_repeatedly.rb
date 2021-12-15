# frozen_string_literal: true

# Helper method repeatedly checks for a probabilistically occurring condition
# by running the given block until either:
#   (a) given condition is detected, or
#   (b) max number of seconds have elapsed.
#
# When adding tests for race conditions, we choose to implement time-limited
# probabilistic test cases, so that rarely-occurring cases might be detected
# over time in CI runs, without slowing down a single run of the test suite
# too much.
#
# @param condition_proc [Proc]
#   Condition proc to check against yielded values, will stop repeating and
#   return if this returns `true`.
#
# @param up_to_max_secs [Numeric]
#   Max number of seconds to run, default: 15.
#
# @yieldreturn [Object]
#   Return value of given block is checked against given condition on each
#   iteration. Final value will be returned to caller.
#
# @return [Object]
#   Returns the final return value of the given block.
def check_repeatedly(condition_proc:, up_to_max_secs: 15.0)
  time_max = Time.now.utc + up_to_max_secs

  loop do
    value = yield
    return value if condition_proc.call(value) || Time.now.utc > time_max
  end
end

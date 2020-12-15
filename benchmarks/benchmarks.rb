# frozen_string_literal: true

require "benchmark/ips"

require "memery"
require "memo_wise"
require "memoist"
require "memoized"
require "memoized/version" # Memoized::VERSION does not get loaded above.
require "memoizer"
require "memoizer/version" # Memoizer::VERSION does not get loaded above.

class BenchmarkSuiteWithoutGC
  def warming(*)
    run_gc
  end

  def running(*)
    run_gc
  end

  def warmup_stats(*); end

  def add_report(*); end

  private

  def run_gc
    GC.enable
    GC.start
    GC.disable
  end
end
suite = BenchmarkSuiteWithoutGC.new

BenchmarkGem = Struct.new(:klass, :inheritance_method, :memoization_method) do
  def benchmark_name
    "#{klass} (#{klass::VERSION})"
  end
end

# We alphabetize this list for easier readability, but shuffle the list before
# using it to minimize the chance that our benchmarks are affected by ordering.
BENCHMARK_GEMS = [
  BenchmarkGem.new(Memery, :include, :memoize),
  BenchmarkGem.new(MemoWise, :prepend, :memo_wise),
  BenchmarkGem.new(Memoist, :extend, :memoize),
  BenchmarkGem.new(Memoized, :include, :memoize),
  BenchmarkGem.new(Memoizer, :include, :memoize)
].shuffle

# Use metaprogramming to ensure that each class is created in exactly the
# the same way.
BENCHMARK_GEMS.each do |benchmark_gem|
  # rubocop:disable Security/Eval
  # rubocop:disable Style/DocumentDynamicEvalDefinition
  eval <<-CLASS, binding, __FILE__, __LINE__ + 1
    class #{benchmark_gem.klass}Example
      #{benchmark_gem.inheritance_method} #{benchmark_gem.klass}

      def no_args
        100
      end
      #{benchmark_gem.memoization_method} :no_args

      def positional_args(a, b)
        100
      end
      #{benchmark_gem.memoization_method} :positional_args

      def keyword_args(a:, b:)
        100
      end
      #{benchmark_gem.memoization_method} :keyword_args

      def positional_and_keyword_args(a, b:)
        100
      end
      #{benchmark_gem.memoization_method} :positional_and_keyword_args

      def positional_and_splat_args(a, *args)
        100
      end
      #{benchmark_gem.memoization_method} :positional_and_splat_args

      def keyword_and_double_splat_args(a:, **kwargs)
        100
      end
      #{benchmark_gem.memoization_method} :keyword_and_double_splat_args

      def positional_splat_keyword_and_double_splat_args(a, *args, b:, **kwargs)
        100
      end
      #{benchmark_gem.memoization_method} :positional_splat_keyword_and_double_splat_args
    end
  CLASS
  # rubocop:enable Style/DocumentDynamicEvalDefinition
  # rubocop:enable Security/Eval
end

# We pre-create argument lists for our memoized methods with arguments, so that
# our benchmarks are running the exact same inputs for each case.
N_UNIQUE_ARGUMENTS = 100
ARGUMENTS = Array.new(N_UNIQUE_ARGUMENTS) { |i| [i, i + 1] }

# We benchmark different cases separately, to ensure that slow performance in
# one method or code path isn't hidden by fast performance in another.

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once to memoize the result value, so our benchmark only tests memoized
    # retrieval time.
    instance.no_args

    x.report("#{benchmark_gem.benchmark_name}: no_args") { instance.no_args }
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, b| instance.positional_args(a, b) }

    x.report("#{benchmark_gem.benchmark_name}: positional_args") do
      ARGUMENTS.each { |a, b| instance.positional_args(a, b) }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, b| instance.keyword_args(a: a, b: b) }

    x.report("#{benchmark_gem.benchmark_name}: keyword_args") do
      ARGUMENTS.each { |a, b| instance.keyword_args(a: a, b: b) }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, b| instance.positional_and_keyword_args(a, b: b) }

    x.report("#{benchmark_gem.benchmark_name}: positional_and_keyword_args") do
      ARGUMENTS.each { |a, b| instance.positional_and_keyword_args(a, b: b) }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, b| instance.positional_and_splat_args(a, b) }

    x.report("#{benchmark_gem.benchmark_name}: positional_and_splat_args") do
      ARGUMENTS.each { |a, b| instance.positional_and_splat_args(a, b) }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, b| instance.keyword_and_double_splat_args(a: a, b: b) }

    x.report(
      "#{benchmark_gem.benchmark_name}: keyword_and_double_splat_args"
    ) do
      ARGUMENTS.each { |a, b| instance.positional_and_splat_args(a: a, b: b) }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each do |a, b|
      instance.positional_splat_keyword_and_double_splat_args(a, b, a: a, b: b)
    end

    x.report(
      "#{benchmark_gem.benchmark_name}: "\
        "positional_splat_keyword_and_double_splat_args"
    ) do
      ARGUMENTS.each do |a, b|
        instance.positional_and_splat_args(a, b, a: a, b: b)
      end
    end
  end

  x.compare!
end

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
  def version
    klass::VERSION
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
  eval <<-CLASS, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
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
    end
  CLASS
end

# We benchmark different cases separately, to ensure that slow performance in
# one method or code path isn't hidden by fast performance in another.
N_UNIQUE_ARGUMENTS = 1_000
N_CALLS_PER_UNIQUE_ARGUMENTS = 1_000
N_INTERATIONS_WITHOUT_ARGUMENTS = N_UNIQUE_ARGUMENTS *
                                  N_CALLS_PER_UNIQUE_ARGUMENTS
ARGUMENTS = Array.new(N_UNIQUE_ARGUMENTS) { |i| [i, i + 1] }

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    example_class = Object.const_get("#{benchmark_gem.klass}Example")
    x.report("#{benchmark_gem.klass} (#{benchmark_gem.version}): no_args") do
      instance = example_class.new
      N_INTERATIONS_WITHOUT_ARGUMENTS.times { instance.no_args }
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    example_class = Object.const_get("#{benchmark_gem.klass}Example")
    x.report(
      "#{benchmark_gem.klass} (#{benchmark_gem.version}): positional_args"
    ) do
      instance = example_class.new
      N_CALLS_PER_UNIQUE_ARGUMENTS.times do
        ARGUMENTS.each { |a, b| instance.positional_args(a, b) }
      end
    end
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    example_class = Object.const_get("#{benchmark_gem.klass}Example")
    x.report(
      "#{benchmark_gem.klass} (#{benchmark_gem.version}): keyword_args"
    ) do
      instance = example_class.new
      N_CALLS_PER_UNIQUE_ARGUMENTS.times do
        ARGUMENTS.each { |a, b| instance.keyword_args(a: a, b: b) }
      end
    end
  end

  x.compare!
end

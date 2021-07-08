# frozen_string_literal: true

require "benchmark/ips"

require "memo_wise"

# Some gems do not yet work in Ruby 3 so we only require them if they're loaded
# in the Gemfile.
%w[memery memoist memoized memoizer ddmemoize].
  each { |gem| require gem if Gem.loaded_specs.key?(gem) }

# The VERSION constant does not get loaded above for these gems.
%w[memoized memoizer].
  each { |gem| require "#{gem}/version" if Gem.loaded_specs.key?(gem) }

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

BenchmarkGem = Struct.new(:klass, :activation_code, :memoization_method) do
  def benchmark_name
    "#{klass} (#{klass::VERSION})"
  end
end

# We alphabetize this list for easier readability, but shuffle the list before
# using it to minimize the chance that our benchmarks are affected by ordering.
# NOTE: Some gems do not yet work in Ruby 3 so we only test with them if they've
# been `require`d.
# rubocop:disable Layout/LineLength
BENCHMARK_GEMS = [
  BenchmarkGem.new(MemoWise, "prepend MemoWise", :memo_wise),
  (BenchmarkGem.new(Memery, "include Memery", :memoize) if defined?(Memery)),
  (BenchmarkGem.new(Memoist, "extend Memoist", :memoize) if defined?(Memoist)),
  (BenchmarkGem.new(Memoized, "include Memoized", :memoize) if defined?(Memoized)),
  (BenchmarkGem.new(Memoizer, "include Memoizer", :memoize) if defined?(Memoizer)),
  (BenchmarkGem.new(DDMemoize, "DDMemoize.activate(self)", :memoize) if defined?(DDMemoize))
].compact.shuffle
# rubocop:enable Layout/LineLength

# Use metaprogramming to ensure that each class is created in exactly the
# the same way.
BENCHMARK_GEMS.each do |benchmark_gem|
  # rubocop:disable Security/Eval
  # rubocop:disable Style/DocumentDynamicEvalDefinition
  eval <<-CLASS, binding, __FILE__, __LINE__ + 1
    class #{benchmark_gem.klass}Example
      #{benchmark_gem.activation_code}

      def no_args
        100
      end
      #{benchmark_gem.memoization_method} :no_args

      def one_positional_arg(a)
        100
      end
      #{benchmark_gem.memoization_method} :one_positional_arg

      def positional_args(a, b)
        100
      end
      #{benchmark_gem.memoization_method} :positional_args

      def one_keyword_arg(a:)
        100
      end
      #{benchmark_gem.memoization_method} :one_keyword_arg

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

    x.report("#{benchmark_gem.benchmark_name}: ()") { instance.no_args }
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(suite: suite)
  BENCHMARK_GEMS.each do |benchmark_gem|
    instance = Object.const_get("#{benchmark_gem.klass}Example").new

    # Run once with each set of arguments to memoize the result values, so our
    # benchmark only tests memoized retrieval time.
    ARGUMENTS.each { |a, _| instance.one_positional_arg(a) }

    x.report("#{benchmark_gem.benchmark_name}: (a)") do
      ARGUMENTS.each { |a, _| instance.one_positional_arg(a) }
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
    ARGUMENTS.each { |a, b| instance.positional_args(a, b) }

    x.report("#{benchmark_gem.benchmark_name}: (a, b)") do
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
    ARGUMENTS.each { |a, _| instance.one_keyword_arg(a: a) }

    x.report("#{benchmark_gem.benchmark_name}: (a:)") do
      ARGUMENTS.each { |a, _| instance.one_keyword_arg(a: a) }
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

    x.report("#{benchmark_gem.benchmark_name}: (a:, b:)") do
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

    x.report("#{benchmark_gem.benchmark_name}: (a, b:)") do
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

    x.report("#{benchmark_gem.benchmark_name}: (a, *args)") do
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
      "#{benchmark_gem.benchmark_name}: (a:, **kwargs)"
    ) do
      ARGUMENTS.each do |a, b|
        instance.keyword_and_double_splat_args(a: a, b: b)
      end
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
      instance.positional_splat_keyword_and_double_splat_args(a, b, b: b, a: a)
    end

    x.report(
      "#{benchmark_gem.benchmark_name}: (a, *args, b:, **kwargs)"
    ) do
      ARGUMENTS.each do |a, b|
        instance.
          positional_splat_keyword_and_double_splat_args(a, b, b: b, a: a)
      end
    end
  end

  x.compare!
end

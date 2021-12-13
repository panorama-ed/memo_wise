# frozen_string_literal: true

require "benchmark/ips"

require "tempfile"
require "memo_wise"

# Some gems do not yet work in Ruby 3 so we only require them if they're loaded
# in the Gemfile.
%w[memery memoist memoized memoizer ddmemoize dry-core].
  each { |gem| require gem if Gem.loaded_specs.key?(gem) }

# The VERSION constant does not get loaded above for these gems.
%w[memoized memoizer].
  each { |gem| require "#{gem}/version" if Gem.loaded_specs.key?(gem) }

# The Memoizable module from dry-core needs to be required manually
require "dry/core/memoizable" if Gem.loaded_specs.key?("dry-core")

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
BENCHMARK_GEMS = [
  BenchmarkGem.new(MemoWise, "prepend MemoWise", :memo_wise),
  (BenchmarkGem.new(DDMemoize, "DDMemoize.activate(self)", :memoize) if defined?(DDMemoize)),
  (BenchmarkGem.new(Dry::Core, "include Dry::Core::Memoizable", :memoize) if defined?(Dry::Core)),
  (BenchmarkGem.new(Memery, "include Memery", :memoize) if defined?(Memery)),
  (BenchmarkGem.new(Memoist, "extend Memoist", :memoize) if defined?(Memoist)),
  (BenchmarkGem.new(Memoized, "include Memoized", :memoize) if defined?(Memoized)),
  (BenchmarkGem.new(Memoizer, "include Memoizer", :memoize) if defined?(Memoizer))
].compact.shuffle

# Use metaprogramming to ensure that each class is created in exactly the
# the same way.
BENCHMARK_GEMS.each do |benchmark_gem|
  eval <<~HEREDOC, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
    # For these methods, we alternately return truthy and falsey values in
    # order to benchmark memoization when the result of a method is falsey.
    #
    # We do this by checking if the first argument to a method is even.
    class #{benchmark_gem.klass}Example
      #{benchmark_gem.activation_code}

      def no_args
        100
      end
      #{benchmark_gem.memoization_method} :no_args

      def one_positional_arg(a)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :one_positional_arg

      def positional_args(a, b)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :positional_args

      def one_keyword_arg(a:)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :one_keyword_arg

      def keyword_args(a:, b:)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :keyword_args

      def positional_and_keyword_args(a, b:)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :positional_and_keyword_args

      def positional_and_splat_args(a, *args)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :positional_and_splat_args

      def keyword_and_double_splat_args(a:, **kwargs)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :keyword_and_double_splat_args

      def positional_splat_keyword_and_double_splat_args(a, *args, b:, **kwargs)
        100 if a.positive?
      end
      #{benchmark_gem.memoization_method} :positional_splat_keyword_and_double_splat_args
    end
  HEREDOC
end

# We pre-create argument lists for our memoized methods with arguments, so that
# our benchmarks are running the exact same inputs for each case.
#
# NOTE: The proportion of falsey results is 1/N_UNIQUE_ARGUMENTS (because for
# the methods with arguments we are truthy for all but the first unique argument
# set). This number was selected as the lowest number such that this logic:
#
#   output = hash[key]
#   if output || hash.key?(key)
#     output
#   else
#     hash[key] = _original_method(...)
#   end
#
# is consistently faster for cached lookups than:
#
#   hash.fetch(key) do
#     hash[key] = _original_method(...)
#   end
#
# as a result of `Hash#[]` having less overhead than `Hash#fetch`.
#
# We believe this is a reasonable choice because we believe most memoized method
# results will be truthy, and so that is the case we should most optimize for.
# However, we do not want to completely remove falsey method results from these
# benchmarks because we do want to catch performance regressions for that case,
# since it has its own "hot path."
N_UNIQUE_ARGUMENTS = 30
ARGUMENTS = Array.new(N_UNIQUE_ARGUMENTS) { |i| [i, i + 1] }
N_TRUTHY_RESULTS = N_UNIQUE_ARGUMENTS - 1
N_RESULT_DECIMAL_DIGITS = 2

# Each method within these benchmarks is initially run once to memoize the
# result value, so our benchmark only tests memoized retrieval time.
benchmark_lambdas = [
  lambda do |x, instance, benchmark_gem|
    instance.no_args

    x.report("#{benchmark_gem.benchmark_name}: ()") do
      instance.no_args
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, _| instance.one_positional_arg(a) }

    x.report("#{benchmark_gem.benchmark_name}: (a)") do
      ARGUMENTS.each { |a, _| instance.one_positional_arg(a) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, b| instance.positional_args(a, b) }

    x.report("#{benchmark_gem.benchmark_name}: (a, b)") do
      ARGUMENTS.each { |a, b| instance.positional_args(a, b) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, _| instance.one_keyword_arg(a: a) }

    x.report("#{benchmark_gem.benchmark_name}: (a:)") do
      ARGUMENTS.each { |a, _| instance.one_keyword_arg(a: a) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, b| instance.keyword_args(a: a, b: b) }

    x.report("#{benchmark_gem.benchmark_name}: (a:, b:)") do
      ARGUMENTS.each { |a, b| instance.keyword_args(a: a, b: b) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, b| instance.positional_and_keyword_args(a, b: b) }

    x.report("#{benchmark_gem.benchmark_name}: (a, b:)") do
      ARGUMENTS.each { |a, b| instance.positional_and_keyword_args(a, b: b) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, b| instance.positional_and_splat_args(a, b) }

    x.report("#{benchmark_gem.benchmark_name}: (a, *args)") do
      ARGUMENTS.each { |a, b| instance.positional_and_splat_args(a, b) }
    end
  end,
  lambda do |x, instance, benchmark_gem|
    ARGUMENTS.each { |a, b| instance.keyword_and_double_splat_args(a: a, b: b) }

    x.report(
      "#{benchmark_gem.benchmark_name}: (a:, **kwargs)"
    ) do
      ARGUMENTS.each do |a, b|
        instance.keyword_and_double_splat_args(a: a, b: b)
      end
    end
  end,
  lambda do |x, instance, benchmark_gem|
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
]

# We benchmark different cases separately, to ensure that slow performance in
# one method or code path isn't hidden by fast performance in another.
benchmark_lambdas.map do |benchmark|
  json_file = Tempfile.new

  Benchmark.ips do |x|
    x.config(suite: suite)
    BENCHMARK_GEMS.each do |benchmark_gem|
      instance = Object.const_get("#{benchmark_gem.klass}Example").new

      benchmark.call(x, instance, benchmark_gem)
    end

    x.compare!
    x.json! json_file.path
  end

  JSON.parse(json_file.read)
end.each_with_index do |benchmark_json, i|
  # We print a comparison table after we run each benchmark to copy into our
  # README.md

  # MemoWise will not appear in the comparison table, but we will use it to
  # compare against other gems' benchmarks
  memo_wise = benchmark_json.find { _1["name"].include?("MemoWise") }
  benchmark_json.delete(memo_wise)

  # Sort benchmarks by gem name to alphabetize our final output table.
  benchmark_json.sort_by! { _1["name"] }

  # Print headers based on the first benchmark_json
  if i.zero?
    benchmark_headers = benchmark_json.map do |benchmark_gem|
      # Gem name is of the form:
      # "MemoWise (1.1.0): ()"
      # We use this mapping to get a header of the form
      # "`MemoWise` (1.1.0)
      gem_name_parts = benchmark_gem["name"].split
      "`#{gem_name_parts[0]}` #{gem_name_parts[1][...-1]}"
    end.join("|")
    puts "|Method arguments|#{benchmark_headers}|"
    puts "#{'|--' * (benchmark_json.size + 1)}|"
  end

  output_str = benchmark_json.map do |bgem|
    # "%.2f" % 12.345 => "12.34" (instead of "12.35")
    #   See: https://bugs.ruby-lang.org/issues/12548
    # 1.00.round(2).to_s => "1.0" (instead of "1.00")
    #
    # So to round and format correctly, we first use Float#round and then %
    "%.#{N_RESULT_DECIMAL_DIGITS}fx" %
      (memo_wise["central_tendency"] / bgem["central_tendency"]).round(N_RESULT_DECIMAL_DIGITS)
  end.join("|")

  name = memo_wise["name"].partition(": ").last
  puts "|`#{name}`#{' (none)' if name == '()'}|#{output_str}|"
end

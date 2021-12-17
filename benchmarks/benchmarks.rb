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
  HEREDOC
end

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
    instance.one_positional_arg(1)

    x.report("#{benchmark_gem.benchmark_name}: (a)") do
      instance.one_positional_arg(1)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.positional_args(1, 2)

    x.report("#{benchmark_gem.benchmark_name}: (a, b)") do
      instance.positional_args(1, 2)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.one_keyword_arg(a: 1)

    x.report("#{benchmark_gem.benchmark_name}: (a:)") do
      instance.one_keyword_arg(a: 1)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.keyword_args(a: 1, b: 2)

    x.report("#{benchmark_gem.benchmark_name}: (a:, b:)") do
      instance.keyword_args(a: 1, b: 2)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.positional_and_keyword_args(1, b: 2)

    x.report("#{benchmark_gem.benchmark_name}: (a, b:)") do
      instance.positional_and_keyword_args(1, b: 2)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.positional_and_splat_args(1, 2)

    x.report("#{benchmark_gem.benchmark_name}: (a, *args)") do
      instance.positional_and_splat_args(1, 2)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.keyword_and_double_splat_args(a: 1, b: 2)

    x.report("#{benchmark_gem.benchmark_name}: (a:, **kwargs)") do
      instance.keyword_and_double_splat_args(a: 1, b: 2)
    end
  end,
  lambda do |x, instance, benchmark_gem|
    instance.positional_splat_keyword_and_double_splat_args(1, 2, b: 3, a: 4)

    x.report("#{benchmark_gem.benchmark_name}: (a, *args, b:, **kwargs)") do
      instance.positional_splat_keyword_and_double_splat_args(1, 2, b: 3, a: 4)
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

# frozen_string_literal: true

require "tempfile"
require "benchmark/ips"
require "gem_bench/jersey"

# Constants used for temp file paths necessary to separate gem namespaces that would otherwise collide.
GITHUB_MAIN = "MemoWise_GitHubMain"
GITHUB_MAIN_BENCHMARK_NAME = "memo_wise-github-main"
LOCAL_BENCHMARK_NAME = "memo_wise-local"

# 1. GitHub version of MemoWise and the local source of MemoWise share a namespace
# 2. memery & alt_memery share the namespace Memery
# This means we must `require: false` in `benchmarks/Gemfile` all, or all but one, of each of these duplicates,
#   or we take care to only load them in discrete Ruby versions,
#   to avoid a namespace collision before re-namespacing duplicates
# NOTE: In future Ruby versions, we can avoid the use of `GemBench` and the
# complexity of `spec.version` in `memo_wise.gemspec` by using namespaces. For
# more context, see: https://bugs.ruby-lang.org/issues/21311
re_namespaced_gems = [
  GemBench::Jersey.new(
    gem_name: "memo_wise",
    trades: {
      "MemoWise" => GITHUB_MAIN
    },
    metadata: {
      activation_code: "prepend #{GITHUB_MAIN}",
      memoization_method: :memo_wise,
    },
  ),
  GemBench::Jersey.new(
    gem_name: "alt_memery",
    trades: {
      "Memery" => "AltMemery"
    },
    metadata: {
      activation_code: "include AltMemery",
      memoization_method: :memoize,
    },
  )
].each(&:doff_and_don) # Copies, re-namespaces, and requires each gem.

# We've already installed the `memo_wise` version on the `main` branch from GitHub in the
# Gemfile, and moved it into a tmp directory and re-namespaced it so it doesn't collide with
# the `MemoWise` constant. Now we require the local version of `memo_wise` to compare
# this branch against it.
require_relative "../lib/memo_wise"

# Load gems that haven't been already loaded by GemBench::Jersey.
require "dry-core"
require "dry/core/memoizable"
require "memery"
require "memoist"
require "short_circu_it"

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

BenchmarkGem = Struct.new(:klass, :activation_code, :memoization_method, :name) do
  def benchmark_name
    "#{name} (#{klass::VERSION})"
  end
end

# We alphabetize this list for easier readability, but shuffle the list before
# using it to minimize the chance that our benchmarks are affected by ordering.
# NOTE: Some gems do not yet work in Ruby 3 so we only test with them if they've
# been `require`d.
benchmarked_gems = re_namespaced_gems.select(&:required?).map do |re_namespaced_gem|
  BenchmarkGem.new(
    re_namespaced_gem.as_klass,
    re_namespaced_gem.metadata[:activation_code],
    re_namespaced_gem.metadata[:memoization_method],
    re_namespaced_gem.gem_name == "memo_wise" ? GITHUB_MAIN_BENCHMARK_NAME : re_namespaced_gem.gem_name,
  )
end
benchmarked_gems.push(
  BenchmarkGem.new(MemoWise, "prepend MemoWise", :memo_wise, LOCAL_BENCHMARK_NAME),
  BenchmarkGem.new(Dry::Core, "include Dry::Core::Memoizable", :memoize, "dry-core"),
  BenchmarkGem.new(Memery, "include Memery", :memoize, "memery"),
  BenchmarkGem.new(Memoist, "extend Memoist", :memoize, "memoist3"),
  BenchmarkGem.new(ShortCircuIt, "include ShortCircuIt", :memoize, "short_circu_it")
)
BENCHMARK_GEMS = benchmarked_gems.compact.shuffle

puts "\nWill BENCHMARK_GEMS:\n\t#{BENCHMARK_GEMS.map(&:benchmark_name).join("\n\t")}\n"

# Use metaprogramming to ensure that each class is created in exactly the
# the same way.
BENCHMARK_GEMS.each do |benchmark_gem| # rubocop:disable Metrics/BlockLength
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
benchmark_jsons = benchmark_lambdas.map do |benchmark|
  json_file = Tempfile.new

  Benchmark.ips do |x|
    # One user reported that a warmup time of 5 seconds was the minimum needed
    # for them to not see whichever MemoWise version (local or GitHub main) runs
    # last getting a speed improvement because Ruby is able to optimize it
    # better on their machine, so we use a 6-second warmup to be safe. This
    # change does not appear to impact results on GitHub Actions.
    # See: https://github.com/panorama-ed/memo_wise/issues/349#issuecomment-2374754550
    x.config(suite: suite, warmup: 6)
    BENCHMARK_GEMS.each do |benchmark_gem|
      instance = Object.const_get("#{benchmark_gem.klass}Example").new

      benchmark.call(x, instance, benchmark_gem)
    end

    x.compare!
    x.json! json_file.path
  end

  JSON.parse(json_file.read)
end

[true, false].each do |github_comparison|
  benchmark_jsons.each_with_index do |benchmark_json, i|
    # We print a comparison table after we run each benchmark to copy into our
    # README.md

    # MemoWise will not appear in the comparison table, but we will use it to
    # compare against other gems' benchmarks
    memo_wise = benchmark_json.find { |json| json["name"].split.first == LOCAL_BENCHMARK_NAME }
    benchmark_json -= [memo_wise]

    github_main = benchmark_json.find { |json| json["name"].split.first == GITHUB_MAIN_BENCHMARK_NAME }
    benchmark_json = github_comparison ? [github_main] : benchmark_json - [github_main]

    # Sort benchmarks by gem name to alphabetize our final output table.
    benchmark_json.sort_by! { |json| json["name"] }

    # Print headers based on the first benchmark_json
    if i.zero?
      benchmark_headers = benchmark_json.map do |benchmark_gem|
        # Gem name is of the form:
        # "memoist (1.1.0): ()"
        # We use this mapping to get a header of the form
        # "`memoist` (1.1.0)"
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

  # Output a blank line between sections
  puts ""
end

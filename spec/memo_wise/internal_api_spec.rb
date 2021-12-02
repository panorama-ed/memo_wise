# frozen_string_literal: true

RSpec.describe MemoWise::InternalAPI do
  describe ".original_class_from_singleton" do
    subject { described_class.original_class_from_singleton(klass) }

    context "when klass is not a singleton class" do
      let(:klass) { String }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    # These test cases would fail due to a JRuby bug
    # Skipping to make build pass until the bug is fixed
    # https://github.com/jruby/jruby/issues/6896
    unless RUBY_PLATFORM == "java"
      context "when klass is a singleton class of an original class" do
        let(:klass) { original_class.singleton_class }

        context "when assigned to a constant" do
          let(:original_class) { String }

          it { is_expected.to eq(original_class) }
        end

        context "when singleton class #to_s convention is not followed" do
          include_context "with context for instance methods"

          let(:original_class) { class_with_memo }
          let(:klass) do
            super().tap do |sc|
              sc.define_singleton_method(:to_s) { "not following convention" }
            end
          end

          it { is_expected.to eq(original_class) }
        end
      end
    end
  end

  describe ".method_arguments" do
    subject { described_class.method_arguments(method) }

    include_context "with context for instance methods"

    {
      no_args: described_class::NONE,
      with_one_positional_arg: described_class::ONE_REQUIRED_POSITIONAL,
      with_one_keyword_arg: described_class::ONE_REQUIRED_KEYWORD,
      with_positional_args: described_class::MULTIPLE_REQUIRED,
      with_keyword_args: described_class::MULTIPLE_REQUIRED,
      with_positional_and_keyword_args: described_class::MULTIPLE_REQUIRED,
      with_optional_positional_args: described_class::SPLAT,
      with_positional_and_splat_args: described_class::SPLAT,
      with_optional_keyword_args: described_class::DOUBLE_SPLAT,
      with_keyword_and_double_splat_args: described_class::DOUBLE_SPLAT,
      with_optional_positional_and_keyword_args: described_class::SPLAT_AND_DOUBLE_SPLAT,
      with_positional_splat_keyword_and_double_splat_args: described_class::SPLAT_AND_DOUBLE_SPLAT
    }.each do |method_name, expected_result|
      context "when given #{method_name} method" do
        let(:method) { class_with_memo.instance_method(method_name) }

        it { is_expected.to eq expected_result }
      end
    end
  end

  describe ".args_str" do
    subject { described_class.args_str(method) }

    include_context "with context for instance methods"

    context "when called on an unexpected method type" do
      let(:method) { class_with_memo.instance_method(:no_args) }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".call_str" do
    subject { described_class.call_str(method) }

    include_context "with context for instance methods"

    context "when called on an unexpected method type" do
      let(:method) { class_with_memo.instance_method(:no_args) }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".key_str" do
    subject { described_class.key_str(method) }

    include_context "with context for instance methods"

    context "when called on an unexpected method type" do
      let(:method) { class_with_memo.instance_method(:no_args) }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".method_visibility" do
    subject { described_class.method_visibility(String, method_name) }

    context "when method_name is not a method on klass" do
      let(:method_name) { :not_a_method }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end

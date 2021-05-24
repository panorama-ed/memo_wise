# frozen_string_literal: true

RSpec.describe MemoWise do # rubocop:disable RSpec/FilePath
  describe "private APIs" do
    describe ".method_visibility" do
      subject { described_class.method_visibility(String, method_name) }

      context "when method_name is not a method on klass" do
        let(:method_name) { :not_a_method }

        it { expect { subject }.to raise_error(ArgumentError) }
      end
    end

    describe ".original_class_from_singleton" do
      subject { described_class.original_class_from_singleton(klass) }

      context "when klass is not a singleton class" do
        let(:klass) { String }

        it { expect { subject }.to raise_error(ArgumentError) }
      end

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
end

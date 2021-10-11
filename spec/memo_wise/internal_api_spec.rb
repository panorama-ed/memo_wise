# frozen_string_literal: true

RSpec.describe MemoWise::InternalAPI do
  describe "#method_visibility" do
    subject { described_class.new(String).method_visibility(method_name) }

    context "when method_name is not a method on klass" do
      let(:method_name) { :not_a_method }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end

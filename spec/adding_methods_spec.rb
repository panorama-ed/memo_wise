# frozen_string_literal: true

RSpec.describe "adding methods" do # rubocop:disable RSpec/DescribeClass
  let(:klass) { Class.new }

  context "when class extends MemoWise" do
    subject { klass.send(:extend, MemoWise) }

    let(:expected_public_instance_methods) do
      %i[
        preset_memo_wise
        reset_memo_wise
      ].to_set
    end

    let(:expected_public_class_methods) do
      %i[
        allocate
        instance_method
        memo_wise
        preset_memo_wise
        reset_memo_wise
      ].to_set
    end

    it "adds expected public *instance* methods only" do
      expect { subject }.
        to change { klass.public_instance_methods.to_set }.
        by(expected_public_instance_methods)
    end

    it "adds no private *instance* methods" do
      expect { subject }.
        not_to change { klass.private_instance_methods.to_set }
    end

    it "adds expected public *class* methods only" do
      expect { subject }.
        to change { klass.singleton_methods.to_set }.
        by(expected_public_class_methods)
    end

    it "adds no private *class* methods" do
      expect { subject }.
        not_to change { klass.singleton_class.private_methods.to_set }
    end
  end
end

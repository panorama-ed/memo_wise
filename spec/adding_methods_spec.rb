# frozen_string_literal: true

RSpec.describe "adding methods" do # rubocop:disable RSpec/DescribeClass
  let(:klass) { Class.new }

  context "when class prepends MemoWise" do
    subject { klass.send(:prepend, MemoWise) }

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

    # These test cases would fail due to a JRuby bug
    # Skipping to make build pass until the bug is fixed
    unless RUBY_PLATFORM == "java"
      context "when a class method is memoized" do
        subject do
          klass.send(:prepend, MemoWise)
          klass.send(:memo_wise, self: :example)
        end

        let(:klass) do
          Class.new do
            def self.example; end
          end
        end

        let(:expected_public_class_methods) { super() << :inherited }

        it "adds expected public *instance* methods only" do
          expect { subject }.
            to change { klass.singleton_methods.to_set }.
            by(expected_public_class_methods)
        end
      end
    end
  end
end

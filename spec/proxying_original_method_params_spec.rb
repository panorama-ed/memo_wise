# frozen_string_literal: true

RSpec.describe "proxying original method params" do # rubocop:disable RSpec/DescribeClass
  shared_examples ".instance_method proxies parameters" do
    subject { unbound_method&.parameters }

    let(:unbound_method) { target.instance_method(method_name) }

    context "when #initialize" do
      let(:method_name) { :initialize }
      let(:expected_parameters) { [[:req, :foo], [:keyreq, :bar]] } # rubocop:disable Style/SymbolArray

      it "returns expected parameters" do
        is_expected.to eq(expected_parameters)
      end

      it "proxies UnboundMethod#parameters via singleton method" do
        expect(unbound_method.singleton_methods).to eq [:parameters]
      end
    end

    context "when #with_optional_positional_and_keyword_args" do
      let(:method_name) { :with_optional_positional_and_keyword_args }
      let(:expected_parameters) { [[:opt, :a], [:key, :b]] } # rubocop:disable Style/SymbolArray

      it "returns expected parameters" do
        is_expected.to eq(expected_parameters)
      end

      it "proxies UnboundMethod#parameters via singleton method" do
        expect(unbound_method.singleton_methods).to eq [:parameters]
      end
    end

    context "when #unmemoized_method" do
      let(:method_name) { :unmemoized_method }
      let(:expected_parameters) { [] }

      it "returns expected parameters" do
        is_expected.to eq(expected_parameters)
      end

      it "does *not* proxy UnboundMethod#parameters via singleton method" do
        expect(unbound_method.singleton_methods).to eq []
      end
    end

    context "when #unmemoized_with_positional_and_keyword_args" do
      let(:method_name) { :unmemoized_with_positional_and_keyword_args }
      let(:expected_parameters) { [[:req, :a], [:keyreq, :b]] } # rubocop:disable Style/SymbolArray

      it "returns expected parameters" do
        is_expected.to eq(expected_parameters)
      end

      it "does *not* proxy UnboundMethod#parameters via singleton method" do
        expect(unbound_method.singleton_methods).to eq []
      end
    end

    context "when method does *not* exist" do
      let(:method_name) { :DOES_NOT_EXIST }

      it "raises NameError" do
        expect { subject }.to raise_error(
          NameError,
          /undefined method (`|')DOES_NOT_EXIST' for class/
        )
      end
    end
  end

  context "when class prepends MemoWise" do
    let(:target) do
      Class.new do
        prepend MemoWise

        def initialize(foo, bar:); end # rubocop:disable Style/RedundantInitialize

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :instance
        )

        def unmemoized_with_positional_and_keyword_args(a, b:) # rubocop:disable Naming/MethodParameterName
          [a, b]
        end
      end
    end

    it_behaves_like ".instance_method proxies parameters"
  end

  context "with a module prepending MemoWise" do
    let(:module1) do
      Module.new do
        prepend MemoWise

        def initialize(foo, bar:); end # rubocop:disable Style/RedundantInitialize

        DefineMethodsForTestingMemoWise.define_methods_for_testing_memo_wise(
          target: self,
          via: :instance
        )

        def unmemoized_with_positional_and_keyword_args(a, b:) # rubocop:disable Naming/MethodParameterName
          [a, b]
        end
      end
    end

    before(:each) { stub_const("Module1", module1) }

    context "when class includes module" do
      let(:target) do
        Class.new do
          include Module1
          def initialize(foo, bar:); end # rubocop:disable Style/RedundantInitialize
        end
      end

      it_behaves_like ".instance_method proxies parameters"
    end

    context "when class prepends MemoWise and includes module" do
      let(:target) do
        Class.new do
          prepend MemoWise
          include Module1
          def initialize(foo, bar:); end # rubocop:disable Style/RedundantInitialize
        end
      end

      it_behaves_like ".instance_method proxies parameters"
    end
  end
end

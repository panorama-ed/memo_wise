# frozen_string_literal: true

RSpec.describe "serializing MemoWise" do # rubocop:disable RSpec/DescribeClass
  context "when serializing using Marshal" do
    let(:class_with_memo) do
      Class.new do
        extend MemoWise

        attr_reader :name, :name_upper_counter, :hello_counter

        def initialize(name:)
          @name = name
          @name_upper_counter = 0
          @hello_counter = 0
        end

        # We test both 0- and 1-arity methods here because they use different
        # storage schemes.
        def name_upper
          @name_upper_counter += 1
          name.upcase
        end
        memo_wise :name_upper

        def hello(n) # rubocop:disable Naming/MethodParameterName
          @hello_counter += 1
          "Hello #{n} times, #{name}!"
        end
        memo_wise :hello
      end
    end

    before :each do
      stub_const("ClassForTest", class_with_memo)
    end

    it "dumps and loads without error" do
      obj1 = ClassForTest.new(name: "foo")
      obj2 = Marshal.load(Marshal.dump(obj1))
      expect(obj2.class).to be(ClassForTest)
      expect(obj2.name).to eq(obj1.name)
    end

    it "dumps and loads memoized state" do
      obj1 = ClassForTest.new(name: "foo")
      obj1.name_upper
      obj1.hello(3)
      obj2 = Marshal.load(Marshal.dump(obj1))

      expect { obj2.name_upper }.
        not_to change { obj2.name_upper_counter }.
        from(1)
      expect { obj2.hello(3) }.
        not_to change { obj2.hello_counter }.
        from(1)

      expect(obj2.name_upper).to eq("FOO")
      expect(obj2.hello(3)).to eq("Hello 3 times, foo!")
    end
  end
end

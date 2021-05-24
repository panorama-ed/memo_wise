# frozen_string_literal: true

RSpec.describe "serializing MemoWise" do # rubocop:disable RSpec/DescribeClass
  context "when serializing using Marshal" do
    let(:class_with_memo) do
      Class.new do
        prepend MemoWise

        attr_reader :name, :name_upper_counter

        def initialize(name:)
          @name = name
          @name_upper_counter = 0
        end

        def name_upper
          @name_upper_counter += 1
          name.upcase
        end
        memo_wise :name_upper
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
      obj2 = Marshal.load(Marshal.dump(obj1))

      expect { obj2.name_upper }.
        not_to change { obj2.name_upper_counter }.
        from(1)

      expect(obj2.name_upper).to eq("FOO")
    end
  end
end

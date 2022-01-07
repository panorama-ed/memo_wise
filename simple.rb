require 'memo_wise'

class Example
  prepend MemoWise

  def example
    rand
  end
  memo_wise :example
end

e = Example.new

arr = 10.times.map { e.example }
p arr
puts arr.uniq == [arr.sample]

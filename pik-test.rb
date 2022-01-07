require "memo_wise"

module M1
  module Concern
    def self.included(includer)
      includer.extend ClassMethods
    end
  end

  module ClassMethods
    prepend MemoWise

    # This rarely changed
    # So should be fine caching on first usage
    def class_level_method
      1 + 1
    end
    memo_wise :class_level_method
  end
end

class C1
  include M1::Concern

  def instance_level_method
    self.class.class_level_method + 1
  end
end

class C2 < C1
  # Empty
end

# These are fine
C1.class_level_method
C1.new.instance_level_method

# These are not
C2.class_level_method
C2.new.instance_level_method

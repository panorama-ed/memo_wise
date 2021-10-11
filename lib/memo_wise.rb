# frozen_string_literal: true

require "set"

require "memo_wise/internal_api"
require "memo_wise/version"

# MemoWise is the wise choice for memoization in Ruby.
#
# - **Q:** What is *memoization*?
# - **A:** [via Wikipedia](https://en.wikipedia.org/wiki/Memoization):
#
#          [Memoization is] an optimization technique used primarily to speed up
#          computer programs by storing the results of expensive function
#          calls and returning the cached result when the same inputs occur
#          again.
#
# To start using MemoWise in a class or module:
#
#   1. Add `extend MemoWise` to the top of the class or module
#   2. Call {.memo_wise} to implement memoization for a given method
#
# **See Also:**
#
#   - {.memo_wise} for API and usage examples.
#   - {file:README.md} for general project information.
#
module MemoWise
  def memo_wise_module
    @memo_wise_module ||= MemoWise::InternalAPI.create_internal_module(self)
  end

  def instance_method(symbol)
    super.tap do |curr_method|
      # Start with calling the original `instance_method` on `symbol`,
      # which returns an `UnboundMethod`.
      #   IF it was replaced by MemoWise,
      #   THEN find the original method's parameters, and modify current
      #        `UnboundMethod#parameters` to return them.
      # For any memoized method - because the original method was renamed,
      # call the original `instance_method` again to find the renamed
      # original method.
      if memo_wise_module.method_defined?(symbol)
        orig_method = curr_method.super_method
        orig_params = orig_method.parameters
        curr_method.define_singleton_method(:parameters) { orig_params }
      end
    end
  end

  # NOTE: See YARD docs for {.memo_wise} directly below this method!
  def memo_wise(method_name_or_hash)
    if Hash === method_name_or_hash
      unless method_name_or_hash.keys == [:self]
        raise ArgumentError, "`:self` is the only key allowed in memo_wise"
      end

      method_name = method_name_or_hash[:self]

      # In Ruby, "class methods" are implemented as normal instance methods
      # on the "singleton class" of a given Class object, found via
      # {Class#singleton_class}.
      # See: https://medium.com/@leo_hetsch/demystifying-singleton-classes-in-ruby-caf3fa4c9d91
      singleton_class.extend(MemoWise)
      return singleton_class.memo_wise(method_name)
    end

    method_name = method_name_or_hash

    raise ArgumentError, "#{method_name.inspect} must be a Symbol" unless method_name.is_a?(Symbol)

    api = MemoWise::InternalAPI.new(self)
    visibility = api.method_visibility(method_name)
    method = instance_method(method_name)

    api.define_memo_wise_method(method, visibility)
  end
end

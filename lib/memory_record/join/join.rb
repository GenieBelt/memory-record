require 'memory_record/errors'
require 'memory_record/join/join_part'
require 'memory_record/join/join_result'
module MemoryRecord
  class Join
    attr_reader :base_key, :base_name, :foreign_key, :foreign_name
    attr_accessor :distinct, :type, :direction
    def initialize(base, base_key, foreign, foreign_key, type=nil, direction=nil)
      @base_store = get_store(base)
      @base_name = get_store_name(base)
      @base_key = base_key
      @foreign_store = get_store(foreign)
      @foreign_name = get_store_name(foreign)
      @foreign_key = foreign_key
      @type = type || :inner
      @direction = direction || :right
      @distinct = false
    end

    def product
      @product ||= get_cross_product
    end

    def [](object)
      product.select { |entry| entry[base_name] == object }
    end

    private

    def get_cross_product
      if @direction == :left
        make_cross @foreign_store, @foreign_name, @foreign_key, @base_store, @base_name, @base_key
      else
        make_cross @base_store, @base_name, @base_key, @foreign_store, @foreign_name, @foreign_key
      end
    end

    def make_cross(left, left_name, left_key,  right, right_name, right_key)
      include_nil = (@type == :outer)
      product = JoinResult.new()
      left.each do |left_object|
        left_value = left_object.send(left_key)
        if left_value.nil? && include_nil
          product << create_join_part(base_name, left_name, left_object, right_name, nil)
        elsif left_value
          matches = right.select { |object| object.send(right_key) == left_value }
          if matches.any?
            if self.distinct
              product << create_join_part(base_name, left_name, left_object, right_name, matches.first )
            else
              matches.each do |right_object|
                product << create_join_part(base_name, left_name, left_object, right_name, right_object )
              end
            end
          elsif include_nil
            product << create_join_part(base_name, left_name, left_object, right_name, nil)
          end
        end
      end
      product
    end

    def create_join_part(base_name, left_name, left_object, right_name, right_object)
      if left_object.kind_of? JoinPart
        left_object.merge(right_name => right_object)
      elsif right_object.kind_of? JoinPart
        right_object.merge(left_name => left_object)
      else
        JoinPart.new(base_name, left_name => left_object, right_name => right_object )
      end
    end

    def get_store(object)
      if object.kind_of?(SearchScope) || (object.kind_of?(Class) && object < MemoryRecord::Base)|| object.kind_of?(MemoryRecord::Store)
        object.all
      else
        raise StatementInvalid, 'wrong type for join'
      end
    end

    def get_store_name(object)
      if object.kind_of?(SearchScope) || (object.kind_of?(Class) && object < MemoryRecord::Base)
        object.store_name.to_sym
      elsif object.kind_of?(MemoryRecord::Store)
        object.name.to_sym
      else
        raise StatementInvalid, 'wrong type for join'
      end
    end
  end
end

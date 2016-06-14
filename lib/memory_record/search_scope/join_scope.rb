module MemoryRecord
  class SearchScope
    class Join
      attr_reader :base_key, :base_name, :foreign_key, :foreign_name
      def initialize(base, base_key, foreign, foreign_key, type=nil, direction=nil)
        @base_store = get_store(base)
        @base_name = get_store_name(base)
        @base_key = base_key
        @foreign_store = get_store(foreign)
        @foreign_name = get_store_name(foreign)
        @foreign_key = foreign_key
        @type = type || :inner
        @direction = direction || :right
      end

      def product
        @product ||= get_cross_product
      end

      private

      def get_cross_product
        if @direction == :left

        end
      end

      def make_cross(left, left_name, left_key,  right, right_name, right_key, include_nil, distinct)
        product = []
        left.each do |left_object|
          left_value = left_object.send(left_key)
          if left_value.nil? && include_nil
            product << {left_name => left_object, right_name => nil }
          elsif left_value
            matches = right.select { |object| object.send(right_key) == left_value }
            if matches.any?
              if distinct
                product << {left_name => left_object, right_name => matches.first }
              else
                matches.each do |right_object|
                  product << {left_name => left_object, right_name => right_object }
                end
              end
            elsif include_nil
              product << {left_name => left_object, right_name => nil }
            end
          end
          product
        end
      end

      def get_store(object)
        if object.kind_of?(SearchScope) || object.kind_of?(MemoryRecord.base)|| object.kind_of?(MemoryRecord::Store)
          object.all
        else
          raise StatementInvalid 'wrong type for join'
        end
      end

      def get_store_name(object)
        if object.kind_of?(SearchScope) || object.kind_of?(MemoryRecord.base)
          object.store_name.to_sym
        elsif object.kind_of?(MemoryRecord::Store)
          object.to_sym
        else
          raise StatementInvalid 'wrong type for join'
        end
      end
    end

    module Joins
      def joins(associations)
        if associations.is_a?(Symbol)
          add_filter ->(object) { object.association(associations.to_sym).scope.any? }
        elsif associations.is_a?(Hash)
          associations.each do |key, value|
            add_filter ->(object) { object.association(key.to_sym).scope.joins(value).any? }
          end
        end
        self
      end

      protected

    end
  end
end


require 'memory_record/errors'

module MemoryRecord
  class SearchScope
    class JoinPart
      def initialize(base_name, result_hash)
        @result = result_hash
        @base = base_name.to_sym
        @keys = result_hash.keys.map(&:to_sym)
      end

      def respond_to?(method)
        super ||
        if @keys.include?(method.to_sym) && method.to_sym != @base
          true
        else
          @result[@base].respond_to?(method)
        end
      end

      def ==(other)
        if other.kind_of? JoinPart
          super
        else
          @result[@base] == other
        end
      end

      def ===(other)
        @result.values.select { |object| object == other }.any?
      end

      def method_missing(method, *args)
        if @keys.include?(method.to_sym) && method.to_sym != @base
          @result[method.to_sym]
        else
          @result[@base].send(method, *args)
        end
      end
    end

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
        product = []
        left.each do |left_object|
          left_value = left_object.send(left_key)
          if left_value.nil? && include_nil
            product << JoinPart.new(base_name, left_name => left_object, right_name => nil )
          elsif left_value
            matches = right.select { |object| object.send(right_key) == left_value }
            if matches.any?
              if self.distinct
                product << JoinPart.new(base_name, left_name => left_object, right_name => matches.first )
              else
                matches.each do |right_object|
                  product << JoinPart.new(base_name, left_name => left_object, right_name => right_object )
                end
              end
            elsif include_nil
              product << JoinPart.new(base_name, left_name => left_object, right_name => nil)
            end
          end
        end
        product
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

    module Joins
      def joins(associations)
        if associations.is_a?(Symbol)
          add_filter ->(object) { object.association(associations.to_sym).scope.any? }
        elsif associations.is_a?(Hash)
          associations.each do |key, value|
            add_filter ->(object) { object.association(key.to_sym).scope.joins(value).any? }
          end
        elsif associations.is_a?(Join)
          if @join
            @join.merge(associations)
          else
            @join = associations
          end
        end
        self
      end

      def _join(base_key, foreign_store, foreign_key)
        Join.new(self, base_key, foreign_store, foreign_key)
      end

      protected

      def hash_search(object, key, value)
        if @join
          object.send(key).scope.where(value).all.any?
        else
          super
        end
      end

      def base_scope
        if @join
          @join.product
        else
          super
        end
      end
    end
  end
end


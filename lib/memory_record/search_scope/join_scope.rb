require 'memory_record/join/join'
module MemoryRecord
  class SearchScope
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


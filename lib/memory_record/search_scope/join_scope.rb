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
        end
        self
      end
    end
  end
end


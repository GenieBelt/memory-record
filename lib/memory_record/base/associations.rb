require 'memory_record/relation_builder/has_many'
require 'memory_record/relation_builder/has_one'
require 'memory_record/relation_builder/belongs_to'
module MemoryRecord
  module Associations
    module ClassMethods
      def belongs_to(name, options=Hash.new)
        MemoryRecord::AssociationBuilder::BelongsTo.build self, name, options
      end

      def has_many(name, options=Hash.new)
        MemoryRecord::AssociationBuilder::HasMany.build self, name, options
      end

      def has_one(name, options=Hash.new)
        MemoryRecord::AssociationBuilder::HasOne.build self, name, options
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
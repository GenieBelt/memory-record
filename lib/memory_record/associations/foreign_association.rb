module MemoryRecord::Associations
  module ForeignAssociation # :nodoc:
    def foreign_key_present?
      if reflection.klass.primary_key
        owner.attribute_present?(reflection.memory_record_primary_key)
      else
        false
      end
    end
  end
end

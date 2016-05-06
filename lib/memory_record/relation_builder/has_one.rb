require 'active_support/core_ext'
require 'memory_record/relation_builder/has_many'
module MemoryRecord
  module RelationBuilder
     class HasOne < HasMany

       def build_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@relation_class}.with_fk(:#{@foreign_key}, self.id).first
end
METHOD
       end

       def build_setter
         clazz.class_eval <<-METHOD
def #{name}=(object)
  object.#{@foreign_key} = self.id
end
         METHOD
       end

       def build_polymorphic_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@relation_class}.with_fk(:#{@foreign_key}, self.id).where(#{@type_field}: self.class.to_s).first
end
         METHOD
       end

       def build_polymorphic_setter
         clazz.class_eval <<-METHOD
def #{name}=(object)
  object.#{@foreign_key} = self.id
  object.#{@type_field} = self.class.to_s
end
         METHOD
       end

       def clazz
         @clazz
       end
     end
  end
end

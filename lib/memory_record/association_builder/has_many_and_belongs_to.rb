require 'active_support/core_ext'
module MemoryRecord
  module RelationBuilder
     class HasManyAndBelongsTo
       def self.build(clazz, name, options=Hash.new)
          new(clazz, name, options).build
       end

       def initialize(clazz, name, options)
         @clazz = clazz
         @name = name
         @options = options
       end

       def build
         get_class_name
         get_foreign_key
         make_foreign_key
         if @options[:as]
           get_type_field
           build_polymorphic_getter
           build_polymorphic_setter
         else
           build_getter
           build_setter
         end
       end

       private

       def get_class_name
         class_name = @options.fetch(:class_name, @name.to_s.singularize)
         @relation_class = class_name.camel_case.constantize
       end

       def get_joint_class_name
         @join_class_name = [@clazz.to_s.split('::').last, @relation_class.to_s.split('::').last].sort.join('')
       end

       def get_joint_class
         begin
           @join_class = Object.const_get @join_class_name
         rescue
           @join_class = build_join_class
         end
       end

       def build_join_class
         clazz = Class.new(MemoryRecord::Base)
         Object.const_set @join_class_name, clazz
         clazz.class_eval <<-ATTRIBUTES
  attributes :id, :#{@l_clazz_fk}, :#{@r_clazz_fk}
         ATTRIBUTES
         clazz.class_store.foreign_key(@l_clazz_fk.to_sym)
         clazz.class_store.foreign_key(@r_clazz_fk.to_sym)
         clazz
       end

       def get_foreign_keys
         @l_clazz_fk = @clazz.to_s.underscore + '_id'
         @r_clazz_fk = @relation_class.to_s.underscore + '_id'
       end


       def build_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@join_class}.with_fk(:#{@foreign_key}, self.id)
end
METHOD
       end


       def build_polymorphic_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@relation_class}.with_fk(:#{@foreign_key}, self.id).where(#{@type_field}: self.class.to_s)
end
         METHOD
       end


       def clazz
         @clazz
       end
     end
  end
end

require 'active_support/core_ext'
module MemoryRecord
  module RelationBuilder
     class HasMany
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
           #build_polymorphic_setter
         else
           build_getter
           #build_setter
         end
       end

       private

       def get_class_name
         class_name = @options.fetch(:class_name, @name)
         @relation_class = class_name.camel_case.constantize
       end

       def get_foreign_key
         if @options[:as]
           @foreign_key = @options[:as] + '_id'
         else
           @foreign_key = @options.fetch(:foreign_key, @relation_class.foreign_key)
         end
       end

       def make_foreign_key
         @relation_class.class_store.foreign_key(@foreign_key.to_sym)
       end

       def get_type_field
         @type_field = @options[:as] + '_type'
       end

       def build_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@relation_class}.where(#{@foreign_key}: self.id)
end
METHOD
       end

       def build_setter
         clazz.class_eval <<-METHOD
def #{name}=(object)
  if object
    self.#{@foreign_key} = object.id
  else
    self.#{@foreign_key} = nil
  end
  object
end
METHOD
       end

       def build_polymorphic_getter
         clazz.class_eval <<-METHOD
def #{name}
  #{@relation_class}.where(#{@foreign_key}: self.id, #{@type_field}: self.class.to_s)
end
         METHOD
       end

       def clazz
         @clazz
       end
     end
  end
end

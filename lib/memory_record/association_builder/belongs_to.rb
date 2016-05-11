require 'active_support/core_ext'
module MemoryRecord
  module RelationBuilder
     class BelongsTo
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
         if @options[:polymorphic]
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
         @relation_class = class_name.to_s.camelize.constantize
       end

       def get_foreign_key
         @foreign_key = @options.fetch(:foreign_key, @relation_class.model_name.singular + '_id')
       end

       def get_type_field
         name = @foreign_key.split('_')
         name.pop
         name << 'type'
         name.join('_')
         @type_field = name
       end

       def build_getter
         clazz.class_eval <<-METHOD
def #{name}
  if #{@foreign_key}
    #{@relation_class}.class_store.get(self.#{@foreign_key})
  else
    nil
  end
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
  if #{@foreign_key}
      clazz = #{@type_field}.constantize
      clazz.class_store.get(self.#{@foreign_key})
  else
    nil
  end
end
         METHOD
       end

       def build_polymorphic_setter
         clazz.class_eval <<-METHOD
def #{name}=(object)
  if object
    self.#{@foreign_key} = object.id
    self.#{@type_field} = object.class.to_s
  else
    self.#{@foreign_key} = nil
    self.#{@type_field} = nil
  end
  object
end
         METHOD
       end

       def clazz
         @clazz
       end

       def name
         @name
       end
     end
  end
end

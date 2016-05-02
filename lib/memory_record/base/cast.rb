module MemoryRecord
  module Cast
    def cast_attribute(attr, value)
      if self.class.attributes_types[attr]
        #TODO cast types
        value
      else
        value
      end
    end
  end
end
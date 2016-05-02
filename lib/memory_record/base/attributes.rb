module MemoryRecord
  module Attributes
    def attributes
      attributes = Hash.new
      attribute_names.each { |attribute| attributes[attribute] = nil }
      attributes
    end

    def assign_attributes(params)
      params.each do |key, value|
        self.send "#{key}=", value
      end
    end

# @return [Array<String>]
    def attribute_names
      self.class.attribute_names.map(&:to_s)
    end


    private
    def temp_attribute_list=(value)
      Thread.current[:MemoryRecordBase] ||= Hash.new
      if value.nil?
        Thread.current[:MemoryRecordBase].delete(self)
      else
        Thread.current[:MemoryRecordBase][self] = value
      end
    end

    def temp_attribute_list
      Thread.current[:MemoryRecordBase] ||= Hash.new
      Thread.current[:MemoryRecordBase][self]
    end

    def attribute_list
      synchronize do
        @attribute_list
      end
    end

    def attribute_list=(new_list)
      synchronize do
        @attribute_list = new_list
      end
    end

    def _attribute_list
      temp_attribute_list || (current_transaction && current_transaction.changes(self)) || attribute_list
    end

    def _start_changes
      if current_transaction && current_transaction[self]
        self.temp_attribute_list ||= Hash.new.merge(current_transaction[self])
      else
        self.temp_attribute_list ||= Hash.new.merge(@attribute_list)
      end
    end

    def write_attribute(name, value)
      return value if value == read_attribute(name)
      _start_changes
      self.send("#{name}_will_change!")
      _attribute_list[name.to_sym] = value
      value
    end

    def read_attribute(name)
      _attribute_list[name.to_sym]
    end
  end
end

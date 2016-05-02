module MemoryRecord
  module Attributes
    module ClassMethods
      # @return [Hash]
      def attributes_types
        @attributes_types || Hash.new
      end

      # @return [Array<Symbol>]
      def attribute_names
        @attributes || Array.new
      end

      private

      # Define attributes methods
      def attributes(*args)
        if args.first.is_a? Hash
          @attributes_types = attributes_types.merge args.first
          @attributes = (attribute_names + args.first.keys).uniq
        else
          @attributes = (attribute_names + args).uniq
        end
        @attributes.each do |name|
          define_attribute_methods name
          class_eval <<-METHOD
  def #{name}
    read_attribute(:#{name})
  end

  def #{name}=(value)
    value = cast_attribute(:#{name}, value)
    write_attribute('#{name}', value)
  end
          METHOD
        end
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

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

    protected

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

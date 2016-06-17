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

      def dangerous_attribute_method?(name)
        @attributes.include?(name.to_sym)
      end

      def has_attribute?(name)
        @attributes && @attributes.include?(name.to_sym)
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

      def timestamps
        if defined? DateTime
          attributes created_at: DateTime, updated_at: DateTime
        else
          attributes created_at: Time, updated_at: Time
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

    def type_for_attribute(attribute)
      @attributes_types[attribute.to_sym]
    end

    def _read_attribute(attribute)
      read_attribute(attribute.to_sym)
    end

    def [](name)
      read_attribute(name.to_sym)
    end

    def []=(name, value)
      write_attribute name, value
    end

    # Returns +true+ if the specified +attribute+ has been set by the user or by a
    # database load and is neither +nil+ nor <tt>empty?</tt> (the latter only applies
    # to objects that respond to <tt>empty?</tt>, most notably Strings). Otherwise, +false+.
    # Note that it always returns +true+ with boolean attributes.
    #
    #   class Task < MemoryRecord::Base
    #   end
    #
    #   task = Task.new(title: '', is_done: false)
    #   task.attribute_present?(:title)   # => false
    #   task.attribute_present?(:is_done) # => true
    #   task.title = 'Buy milk'
    #   task.is_done = true
    #   task.attribute_present?(:title)   # => true
    #   task.attribute_present?(:is_done) # => true
    def attribute_present?(attribute)
      value = _read_attribute(attribute)
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end

    # Returns true if the given attribute exists, otherwise false.
    #
    #   class Person < MemoryRecord::Base
    #     attributes :name, :age
    #   end
    #
    #   Person.has_attribute?('name')   # => true
    #   Person.has_attribute?(:age)     # => true
    #   Person.has_attribute?(:nothing) # => false
    def has_attribute?(attr_name)
      attribute_names.include?(attr_name.to_sym)
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

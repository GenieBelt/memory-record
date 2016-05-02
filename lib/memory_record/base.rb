require_relative 'base/cast.rb'
require 'active_model'
module MemoryRecord
  class Base
    include Base::Cast
    include ActiveModel::AttributeMethods
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Model
    include ActiveModel::Serialization

    class << self

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
          @attributes = (attributes + args.first.keys).uniq
        else
          @attributes = (attributes + args).uniq
        end
        @attributes.each do |name|
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

    def initialize(params=Hash.new)
      @attribute_list = Hash.new
      @temp_attribute_list = nil
    end

    def attribute_names
      self.attribute_names.map(&:to_s)
    end

    def read_attribute(name)
      _attribute_list[name.to_sym]
    end

    def write_attribute(name, value)
      return value if value == read_attribute(name)
      _start_changes
      self.send("#{name}_will_change!")
      _attribute_list[name] = value
      value
    end

    def _start_changes
      @persisted = false
      if current_transaction
        current_transaction.changes(self) ||= Hash.new.merge(@attribute_list)
      else
        @temp_attribute_list ||= Hash.new.merge(@attribute_list)
      end
    end

    def _attribute_list
      if current_transaction
        current_transaction.changes(self) || @temp_attribute_list || @attribute_list
      end
    end

    # @return [MemoryRecord::Transaction]
    def current_transaction
      Thread.current[:MemoryRecordTransaction]
    end
  end
end
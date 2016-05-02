require 'memory_record/base/cast'
require 'memory_record/transactions/abstract_transaction'
require 'memory_record/base/transactional'
require 'active_model'
require 'memory_record/store'
module MemoryRecord
  class RecordNotSaved < Exception; end
  class Base
    # noinspection RubyClassVariableUsageInspection
    @@main_store = MainStore.new
    include MemoryRecord::Transactional
    include MemoryRecord::Cast
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

      # @return [ObjectStore]
      def class_store
        # noinspection RubyClassVariableUsageInspection
        @store ||= @@main_store.get_store_for self
      end

      def next_id
        internal_lock.synchronize do
          @next_id ||=0
          @next_id += 1
          @next_id
        end
      end

      def create(params)
        object = self.new(params)
        object.save
        object
      end

      def create!(params)
        object = self.new(params)
        object.save!
        object
      end

      private

      def internal_lock
        @lock ||= Mutex.new
      end

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

    def initialize(params=Hash.new)
      @attribute_list = Hash.new
      @mutex = Mutex.new
      assign_attributes params
    end

    def id
      read_attribute id_key
    end

    def id=(value)
      value = cast_attribute(id_key, value)
      write_attribute(id_key, value)
    end

    # @return [Array<String>]
    def attribute_names
      self.class.attribute_names.map(&:to_s)
    end


    def reload!
      self.temp_attribute_list = nil
      clear_changes_information
      unlock!
      self
    end

    def rollback!
      restore_attributes
      unlock!
      self
    end

    def persisted?
      !!self.temp_attribute_list
    end

    define_model_callbacks :commit

    def commit(transaction, values)
      raise unless transaction.kind_of?(Transaction) || transaction ==self
      run_callbacks(:commit) do
        self.attribute_list = values
      end
    ensure
      unlock!
    end

    define_model_callbacks :save
    define_model_callbacks :update
    define_model_callbacks :create
    def save
      if self.valid?
        run_callbacks(new_record? ? :create : :update) do
          run_callbacks(:save) do
            persists_local_changes
            add_to_store
          end
        end
        self
      else
        unlock!
        false
      end
    end

    def save!
      save || raise(MemoryRecord::RecordNotSaved.new "Record not saved! - #{self}")
    end

    def assign_attributes(params)
      params.each do |key, value|
        self.send "#{key}=", value
      end
    end

    def new_record?
      !(id && self.class.class_store.get(id))
    end

    def lock!
      @mutex.lock unless @mutex.owned?
    end

    def unlock!
      @mutex.unlock if @mutex.owned?
    end

    define_model_callbacks :destroy

    def destroy
      run_callbacks(:save) do
        self.temp_attribute_list = nil
        if current_transaction
          current_transaction.destroy self
        else
          commit_destroy
        end
      end
    end

    def commit_destroy
      self.temp_attribute_list = nil
      self.class.class_store.remove(self)
    end

    def to_s
      "#{self.class}##{self.id}"
    end

    def attributes
      attributes = Hash.new
      attribute_names.each { |attribute| attributes[attribute] = nil }
      attributes
    end

    private

    def read_attribute(name)
      _attribute_list[name.to_sym]
    end

    def write_attribute(name, value)
      return value if value == read_attribute(name)
      _start_changes
      self.send("#{name}_will_change!")
      _attribute_list[name.to_sym] = value
      value
    end

    def _start_changes
      if current_transaction && current_transaction[self]
        self.temp_attribute_list ||= Hash.new.merge(current_transaction[self])
      else
        self.temp_attribute_list ||= Hash.new.merge(@attribute_list)
      end
    end

    def _attribute_list
      temp_attribute_list || (current_transaction && current_transaction.changes(self)) || attribute_list
    end


    def id_key
      key = nil
      if self.class.respond_to? :id_key
        key = self.class.id_key
      elsif self.class.respond_to? :primary_key
        key = self.class.primary_key
      end
      key || :id
    end

    def synchronize
      if @mutex.owned?
        yield
      else
        @mutex.synchronize do
          yield
        end
      end
    end

    def persists_local_changes
      if self.current_transaction
        self.current_transaction[self] = temp_attribute_list
      else
        commit self, temp_attribute_list
      end
      self.temp_attribute_list = nil
    end

    def add_to_store
      unless id
        self.attribute_list = self.attribute_list.merge(id: self.class.next_id)
        self.class.class_store.class_store self
      end
    end

    def attribute_list=(new_list)
      synchronize do
        @attribute_list = new_list
      end
    end

    def attribute_list
      synchronize do
        @attribute_list
      end
    end

    def temp_attribute_list
      Thread.current[:MemoryRecordBase] ||= Hash.new
      Thread.current[:MemoryRecordBase][self]
    end

    def temp_attribute_list=(value)
      Thread.current[:MemoryRecordBase] ||= Hash.new
      if value.nil?
        Thread.current[:MemoryRecordBase].delete(self)
      else
        Thread.current[:MemoryRecordBase][self] = value
      end
    end
  end
end
require 'memory_record/base/cast'
require 'memory_record/base/attributes'
require 'memory_record/transactions/abstract_transaction'
require 'memory_record/base/transactional'
require 'active_model'
require 'memory_record/store'
module MemoryRecord
  class RecordNotSaved < Exception; end
  class RecordNotCommitted <  Exception; end
  class Base
    @@main_store = MainStore.new
    include MemoryRecord::Attributes # noinspection RubyClassVariableUsageInspection
    include MemoryRecord::Transactional
    include MemoryRecord::Cast
    include ActiveModel::AttributeMethods
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Model
    include ActiveModel::Serialization

    class << self
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
      raise RecordNotCommitted.new "Cannot commit #{self}" unless transaction.kind_of?(Transaction) || transaction ==self
      run_callbacks(:commit) do
        self.attribute_list = values
        add_to_store
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
            add_to_store unless current_transaction
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

    def new_record?
      !(id && self.class.class_store.get(id))
    end

    def destroyed?
      synchronize do
        !!@destroyed
      end
    end

    def lock!
      @mutex.lock unless @mutex.owned?
    end

    def unlock!
      @mutex.unlock if @mutex.owned?
    end

    define_model_callbacks :destroy

    def destroy
      run_callbacks(:destroy) do
        delete
      end
    end

    def delete
      self.temp_attribute_list = nil
      if current_transaction
        current_transaction.destroy self
      else
        _delete
      end
    end

    def commit_destroy(transaction)
      raise RecordNotCommitted.new "Cannot commit #{self}" unless transaction.kind_of?(Transaction)
      _delete
    end

    def remove_from_store
      self.class.class_store.remove(self)
    end

    def mark_as_deleted
      self.temp_attribute_list = nil
      self.synchronize do
        @destroyed = true
      end
    end

    def to_s
      "#{self.class}##{self.id}(#{attribute_names.join(', ')})"
    end

    private

    def _delete
      mark_as_deleted
      remove_from_store
    ensure
      unlock!
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


  end
end
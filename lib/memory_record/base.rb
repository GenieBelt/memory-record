require 'memory_record/base/cast'
require 'memory_record/base/attributes'
require 'memory_record/transactions/abstract_transaction'
require 'memory_record/base/transactional'
require 'memory_record/base/scope'
require 'memory_record/base/locking'
require 'memory_record/base/relations'
require 'memory_record/base/persisted'
require 'memory_record/core'
require 'active_model'
require 'memory_record/inheritance'
require 'memory_record/store'
require 'memory_record/errors'
require 'memory_record/associations'
require 'memory_record/reflection'
module MemoryRecord
  class Base
    # noinspection RubyClassVariableUsageInspection
    @@main_store = MainStore.new
    include ActiveModel::AttributeMethods
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Model
    include ActiveModel::Serialization
    include MemoryRecord::Locking
    include MemoryRecord::Core
    include MemoryRecord::Persisted
    include MemoryRecord::Attributes
    include MemoryRecord::Inheritance
    include MemoryRecord::Transactional
    include MemoryRecord::Cast
    include MemoryRecord::Scope
    include MemoryRecord::Associations
    include MemoryRecord::Reflection

    mattr_accessor :belongs_to_required_by_default, instance_accessor: false

    class << self
      # @return [ObjectStore]
      def class_store
        # noinspection RubyClassVariableUsageInspection
        unless @store
          clazz  = parent_class
          @store = @@main_store.get_store_for clazz
        end
        @store
      end

      def store_name
        class_store.name
      end

      def main_store
        @@main_store
      end

      def next_id
        internal_lock.synchronize do
          @next_id ||=0
          @next_id += 1
          @next_id
        end
      end

      def create(params=nil)
        object = self.new(params)
        object.save
        object
      end

      def create!(params=nil)
        object = self.new(params)
        object.save!
        object
      end

      def delete_all
        class_store.clean_store
      end

      private

      def parent_class
        unless @parent_class
          clazz = self
          while clazz.superclass < MemoryRecord::Base
            clazz = clazz.superclass
          end
          @parent_class = clazz
        end
        @parent_class
      end

      def internal_lock
        @lock ||= Mutex.new
      end
    end

    def id
      read_attribute id_key
    end

    def id=(value)
      value = cast_attribute(id_key, value)
      write_attribute(id_key, value)
    end


    def to_s
      "#{self.class}[#{self.id}](#{attribute_names.join(', ')})"
    end

    def inspect
      "#{self.class}[#{self.id}](#{_attribute_list})"
    end

    def rollback!
      _restore_attributes
      unlock!
      self
    end

    private

    def _restore_attributes
      if respond_to? :restore_attributes
        restore_attributes
      else
        @changed_attributes.clear
        self.temp_attribute_list = nil
      end
    end

    def set_timestamps
      if new_record?
        if respond_to? :created_at
          self.created_at = Time.now
        end
      end
      if respond_to? :updated_at
        self.updated_at = Time.now
      end
    end
  end
  ActiveSupport.run_load_hooks(:memory_record, Base)
end
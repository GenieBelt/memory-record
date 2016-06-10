module MemoryRecord
  module Persisted
    extend ActiveSupport::Concern

    included do
      define_model_callbacks :commit
      define_model_callbacks :save
      define_model_callbacks :update
      define_model_callbacks :create
      define_model_callbacks :destroy
    end

    def reload!
      self.temp_attribute_list = nil
      _clear_changes_information
      unlock!
      self
    end

    alias reload reload!

    def persisted?
      !(new_record? || destroyed?)
    end

    def commit(transaction, values)
      raise RecordNotCommitted.new "Cannot commit #{self}" unless transaction.kind_of?(Transaction) || transaction ==self
      run_callbacks(:commit) do
        self.attribute_list = values
        self.temp_attribute_list = nil
        add_to_store
      end
    ensure
      unlock!
    end

    def save
      if self.valid?
        run_callbacks(new_record? ? :create : :update) do
          run_callbacks(:save) do
            set_timestamps
            persists_local_changes
            _clean_dirty_attributes
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

    protected


    def _delete
      mark_as_deleted
      remove_from_store
    ensure
      unlock!
    end

    def mark_as_deleted
      self.temp_attribute_list = nil
      self.synchronize do
        @destroyed = true
      end
    end

    def remove_from_store
      self.class.class_store.remove(self)
    end

    def _clear_changes_information
      if self.respond_to? :clear_changes_information
        clear_changes_information
      else
        @changed_attributes.clear
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

    def _clean_dirty_attributes
      if respond_to? :changes_applied
        changes_applied
      else
        @previously_changed = changes
        @changed_attributes.clear
      end
    end

    def add_to_store
      unless id
        self.attribute_list = self.attribute_list.merge(id_key => self.class.next_id)
      end
      self.class.class_store.store self
    end
  end
end
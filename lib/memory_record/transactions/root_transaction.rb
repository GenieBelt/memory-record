require 'memory_record/transactions/abstract_transaction'
require 'memory_record/transactions/root_transaction'
module MemoryRecord
  class RootTransaction < Transaction
    def initialize
      super
      @child_transactions = []
    end

    def child_transactions
      @child_transactions
    end
  end

  class ChildTransaction < RootTransaction
    def initialize(parent)
      super()
      @parent = parent
    end

    def commit!
      @object_changes.each do |object, changes|
        if @parent.changes(object)
          @parent.changes.merge! changes
        else
          @parent.changes(object, changes)
        end
      end
    end
  end
end

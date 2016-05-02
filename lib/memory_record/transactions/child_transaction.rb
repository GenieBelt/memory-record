require 'memory_record/transactions/root_transaction'
module MemoryRecord
  class ChildTransaction < RootTransaction
    # @param parent [MemoryRecord::RootTransaction]
    def initialize(parent)
      super()
      @parent = parent
      @parent.child_transactions << self
    end

    def commit!
      @object_changes.each do |object, changes|
        if @parent[object]
          @parent[object].merge! changes
        else
          @parent[object] = changes
        end
      end
      @parent.child_transactions.delete self
    end

    def rollback!
      super
      @parent.child_transactions.delete self
    end
  end
end

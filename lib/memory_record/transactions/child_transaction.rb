require 'memory_record/transactions/abstract_transaction'
module MemoryRecord
  class ChildTransaction < RootTransaction
    def initialize(parent)
      super()
      @parent = parent
    end

    def commit!
      @object_changes.each do |object, changes|
        if @parent[object]
          @parent[object].merge! changes
        else
          @parent[object] = changes
        end
      end
    end
  end
end

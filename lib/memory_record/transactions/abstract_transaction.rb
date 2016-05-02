module MemoryRecord
  class Transaction
    def initialize
      @object_changes = Hash.new
    end

    def [](object)
      @object_changes[object]
    end

    def []=(object,values)
      @object_changes[object] = values
    end

    def changes(object)
      @object_changes[object]
    end

    def rollback!
      @object_changes = Hash.new
    end

    def commit!
      @object_changes.each do |object, values|
        object.commit(self, values)
      end
    end
  end
end

module MemoryRecord
  class Transaction
    def initialize
      @object_changes = Hash.new
      @destroy_objects = []
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

    def destroy(object)
      @destroy_objects << object
    end

    def rollback!
      @object_changes.keys.each do |object|
        object.unlock!
      end
      @destroy_objects.each do |object|
        object.unlock!
      end
      @object_changes = Hash.new
      @destroy_objects = []
    end

    def commit!
      @object_changes.each do |object, values|
        object.commit(self, values)
      end
      @destroy_objects.each do |object|
        object.commit_destroy
      end
    end
  end
end

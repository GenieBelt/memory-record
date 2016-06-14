require 'memory_record/associations/join_dependency/join_part'

module MemoryRecord
  module Associations
    class JoinDependency # :nodoc:
      class JoinBase < JoinPart # :nodoc:
        def match?(other)
          return true if self == other
          super && base_klass == other.base_klass
        end

        def table
          base_klass.class_store
        end

        def aliased_table_name
          base_klass.store_name
        end
      end
    end
  end
end

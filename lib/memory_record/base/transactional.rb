require 'memory_record/transactions/child_transaction'
require 'memory_record/transactions/root_transaction'
module MemoryRecord
  class Rollback < Exception;
    def initialize
      super 'Rollback'
    end
  end
  module Transactional
    module ClassMethods
      def transaction(options=Hash.new)
        old_transaction = current_transaction
        Thread.current[:MemoryRecordTransaction] = new_transaction options
        begin
          current_transaction.begin_transaction
          yield
          current_transaction.perform_commit
        rescue MemoryRecord::Rollback
          current_transaction.perform_rollback
        rescue
          current_transaction.perform_rollback
          raise
        ensure
          Thread.current[:MemoryRecordTransaction] = old_transaction
        end
      end

      def new_transaction(options)
        if options[:requires_new]
          MemoryRecord::RootTransaction.new
        else
          if current_transaction
            MemoryRecord::ChildTransaction.new(current_transaction)
          else
            MemoryRecord::RootTransaction.new
          end
        end
      end

      def rollback
        raise MemoryRecord::Rollback.new
      end

      # @return [MemoryRecord::Transaction]
      def current_transaction
        Thread.current[:MemoryRecordTransaction]
      end
    end

    # @return [MemoryRecord::Transaction]
    def current_transaction
      Thread.current[:MemoryRecordTransaction]
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
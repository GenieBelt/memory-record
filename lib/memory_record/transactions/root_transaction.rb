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

    def commit!
      @child_transactions.each { |t| t.commit! }
      super
    end

    def rollback!
      @child_transactions.each { |t| t.rollback! }
      super
    end
  end
end

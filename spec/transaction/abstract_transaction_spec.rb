require 'spec_helper'
require 'memory_record/transactions/abstract_transaction'

describe MemoryRecord::Transaction do

  it 'should initialize' do
    expect { MemoryRecord::Transaction.new }.not_to raise_error
  end

  it 'should store changes' do
    transaction = MemoryRecord::Transaction.new
    expect(transaction[:foo]).to be_nil
    expect { transaction[:foo] = :bar }.not_to raise_error
    expect(transaction[:foo]).to eq :bar
  end

  it 'should clear changes on rollback' do
    transaction = MemoryRecord::Transaction.new
    transaction[:foo] = :bar
    expect(transaction[:foo]).to eq :bar
    transaction.perform_rollback
    expect(transaction[:foo]).to be_nil
  end
end
require 'spec_helper'
require 'memory_record/store'

describe MemoryRecord::Store do

  context 'Abstract store' do
    it 'should initialize' do
      store = MemoryRecord::Store.new
      expect(store).not_to be_nil
    end

    it 'should be able to synchornize stuff' do
      store = MemoryRecord::Store.new
      expect do
        store.synchronize do
          puts 'test'
        end
      end.not_to raise_error
    end
  end
end
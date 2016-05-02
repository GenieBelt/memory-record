require 'spec_helper'
require 'memory_record/base'

describe 'Base storing' do

  before(:each) do
    undefine_class :Foo
    class Foo < MemoryRecord::Base
      attributes :id, :bar
    end
  end

  it 'should return next id' do
    expect(Foo.next_id).to eq 1
  end

  it 'should be able to save new object' do

  end
end
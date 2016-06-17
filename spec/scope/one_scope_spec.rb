require 'spec_helper'
require 'memory_record/search_scope'
require 'memory_record/base'

describe 'OneScope' do

  it 'should be an array' do
    expect(MemoryRecord::SearchScope::OneScope.new).to be_kind_of Array
  end

  it 'should initialize like array' do
    expect(MemoryRecord::SearchScope::OneScope.new([:a])).to eq [:a]
  end

  it 'should be able to create search scope from object' do
    undefine_class :OneScopeExample
    class OneScopeExample < MemoryRecord::Base; end
    object = OneScopeExample.create!
    expect(object.scope).to be_kind_of(OneScopeExample::SearchScope)
    expect(object.scope.all).to eq [object]
  end
end
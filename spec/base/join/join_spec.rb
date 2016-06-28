require 'spec_helper'
require 'memory_record/base'
require 'memory_record/join/join'

class AJoinTest < MemoryRecord::Base
  attributes :name, :id, :b_id
end

class BJoinTest < MemoryRecord::Base
  attributes :name, :id, :a_id
end

describe 'Join' do

  it 'should should return proper product' do
    AJoinTest.class_store.clean_store
    BJoinTest.class_store.clean_store

    a_objects = [AJoinTest.create(name: :a), AJoinTest.create(name: :b), AJoinTest.create(name: :c) ]
    b_objects = [BJoinTest.create(name: :a), BJoinTest.create(name: :b)]

    join = MemoryRecord::Join.new(AJoinTest, :name, BJoinTest, :name)
    product = join.product
    expect(product).to be_kind_of Array
    expect(product.first).to be_kind_of MemoryRecord::JoinPart
    expect(product.first.b_join_test).to be_kind_of BJoinTest
    expect(product.count).to eq 2
    expect(product.first).to eq a_objects.first
    expect(product.last).to eq a_objects.second
  end
end
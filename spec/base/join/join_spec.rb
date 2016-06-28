require 'spec_helper'
require 'memory_record/base'
require 'memory_record/join/join'

class AJoinTest < MemoryRecord::Base
  attributes :name, :id, :c_id
end

class BJoinTest < MemoryRecord::Base
  attributes :name, :id, :a_id
end

class CJoinTest < MemoryRecord::Base
  attributes :name, :id, :b_id
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
    expect(product).to be_kind_of MemoryRecord::JoinResult
    expect(product.first).to be_kind_of MemoryRecord::JoinPart
    expect(product.first.b_join_test).to be_kind_of BJoinTest
    expect(product.count).to eq 2
    expect(product.first).to eq a_objects.first
    expect(product.last).to eq a_objects.second
  end

  it 'should join with join result' do
    AJoinTest.class_store.clean_store
    BJoinTest.class_store.clean_store

    a_objects = [AJoinTest.create(name: :a), AJoinTest.create(name: :b), AJoinTest.create(name: :c) ]
    b_objects = [BJoinTest.create(name: :a), BJoinTest.create(name: :b)]
    c_objects = [CJoinTest.create(name: :a), CJoinTest.create(name: :c), CJoinTest.create(name: :d)]

    join = MemoryRecord::Join.new(AJoinTest, :name, BJoinTest, :name)
    nested_join = MemoryRecord::Join.new(join, :name, CJoinTest, :name)
    product = nested_join.product
    expect(product).to be_kind_of Array
    expect(product).to be_kind_of MemoryRecord::JoinResult
    expect(product.first).to be_kind_of MemoryRecord::JoinPart
    expect(product.first.b_join_test).to be_kind_of BJoinTest
    expect(product.first.c_join_test).to be_kind_of CJoinTest
  end
end
require 'spec_helper'
require 'memory_record/store'

describe MemoryRecord::MainStore do

  before(:each) do
    undefine_class :FooBar
    class FooBar < AttributedObject; end
  end

  it 'should initialize with no arguments' do
    expect { MemoryRecord::MainStore.new }.not_to raise_error
  end

  it 'should return object store for class' do
    store = MemoryRecord::MainStore.new
    class_store = store.get_store_for FooBar
    expect(class_store).not_to be_nil
    expect(class_store.clazz).to eq FooBar
  end

  it 'should store object' do
    foo = FooBar.new id: 1, user_id: 2
    store = MemoryRecord::MainStore.new
    expect { store.store(foo) }.not_to raise_error
    expect(store.get_store_for(FooBar).all).to include FooBar
  end

  it 'should get object' do
    foo = FooBar.new id: 1, user_id: 2
    store = MemoryRecord::MainStore.new
    expect { store.store(foo) }.not_to raise_error
    expect(store.get_object(FooBar, 1)).to eq foo
  end

  it 'should remove object' do
    foo = FooBar.new id: 1, user_id: 2
    store = MemoryRecord::MainStore.new
    expect { store.store(foo) }.not_to raise_error
    expect(store.get_store_for(FooBar).all).to include FooBar
    expect { store.remove foo }.not_to raise_error
    expect(store.get_store_for(FooBar).all).not_to include foo
  end
end
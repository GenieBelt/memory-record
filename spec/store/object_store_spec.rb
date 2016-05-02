require 'spec_helper'
require 'memory_record/store'

describe MemoryRecord::ObjectStore do

  it 'should initialize correctly' do
    class Foo; end
    store = MemoryRecord::ObjectStore.new Foo
    expect(store.clazz).to eq Foo
    undefine_class :Foo
  end

  context 'store using id' do
    before(:each) do
      undefine_class :Foo
      class Foo; attr_accessor :id; end
    end

    it 'should be able to store object' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new
      foo.id = 1
      store.store foo
      expect(store.all).to include foo
    end

    it 'should be able to get object by id' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new
      foo.id = 1
      store.store foo

      expect(store.get 1).to eq foo
    end
  end

  context 'custom id key' do
    before(:each) do
      undefine_class :Foo
      class Foo < AttributedObject
        attr_accessor :foo_id
        def self.id_key
          :foo_id
        end
      end
    end

    it 'should be able to store object' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new foo_id: 1
      store.store foo
      expect(store.all).to include foo
    end

    it 'should be able to get object by id' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new foo_id: 1
      store.store foo

      expect(store.get 1).to eq foo
    end
  end

  context 'custom primary_key' do
    before(:each) do
      undefine_class :Foo
      class Foo < AttributedObject
        attr_accessor :foo_id
        def self.primary_key
          :foo_id
        end
      end
    end

    it 'should be able to store object' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new foo_id: 1
      store.store foo
      expect(store.all).to include foo
    end

    it 'should be able to get object by id' do
      store = MemoryRecord::ObjectStore.new Foo
      foo = Foo.new foo_id: 1
      store.store foo

      expect(store.get 1).to eq foo
    end
  end

  context 'foreign key' do
    before(:each) do
      undefine_class :Foo
      class Foo < AttributedObject; end
    end

    let(:store) { MemoryRecord::ObjectStore.new Foo }

    it 'should be able to get by foreign key' do
      foo1 = Foo.new id: 1, bar_id: 1, user_id: 2
      foo2 = Foo.new id: 2, bar_id: 1, user_id: 1
      foo3 = Foo.new id: 3, bar_id: 2, user_id: 1
      store.foreign_key :bar_id
      store.foreign_key :user_id
      store.store(foo1)
      store.store(foo2)
      store.store(foo3)
      expect(store.get_with_fk :bar_id, 1).to include foo1, foo2
      expect(store.get_with_fk :bar_id, 1).not_to include foo3
      expect(store.get_with_fk :user_id, 2).to include foo1
      expect(store.get_with_fk :user_id, 2).not_to include foo3, foo2
    end

    it 'should reindex store if new fk added' do
      foo1 = Foo.new id: 1, bar_id: 1, user_id: 2
      foo2 = Foo.new id: 2, bar_id: 1, user_id: 1
      foo3 = Foo.new id: 3, bar_id: 2, user_id: 1
      store.store(foo1)
      store.store(foo2)
      store.store(foo3)
      store.foreign_key :bar_id
      store.foreign_key :user_id
      expect(store.get_with_fk :bar_id, 1).to include foo1, foo2
      expect(store.get_with_fk :bar_id, 1).not_to include foo3
      expect(store.get_with_fk :user_id, 2).to include foo1
      expect(store.get_with_fk :user_id, 2).not_to include foo3, foo2
    end

    it 'should properly remove object' do
      foo = Foo.new id: 1, bar_id: 1, user_id: 2
      store.foreign_key :bar_id
      store.foreign_key :user_id
      store.store(foo)

      store.remove(foo)
      expect(store.get_with_fk :bar_id, 1).not_to include foo
      expect(store.get_with_fk :user_id, 2).not_to include foo
      expect(store.all).not_to include foo
    end
  end
end
require 'spec_helper'
require 'memory_record/base'

describe 'belongs_to association' do

  before(:each) do
    MemoryRecord::Base.main_store.clean_store
  end

  context 'define on model' do
    it 'should define with just name' do
      undefine_class :Foo, :Bar
      class Bar < MemoryRecord::Base
        attributes id: Integer, name: String
      end
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, bar_id: Integer
          belongs_to :bar
        end
      end.not_to raise_error
    end

    it 'should define with fk' do
      undefine_class :Foo, :Bar
      class Bar < MemoryRecord::Base
        attributes id: Integer, name: String
      end
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, custom_bar_id: Integer
          belongs_to :bar, foreign_key: :custom_bar_id
        end
      end.not_to raise_error
    end
  end

  context 'normal' do
    before(:all) do
      undefine_class :Handle, :Mug
      class Mug < MemoryRecord::Base
        attributes id: Integer, name: String
      end
      class Handle < MemoryRecord::Base;
        attributes id: Integer, mug_id: Integer
        belongs_to :mug
      end
    end

    it 'should set proper values' do
      mug = Mug.create! name: 'test'
      handle = Handle.create! mug: mug
      expect(handle.mug_id).to eq mug.id
    end

    it 'should load proper values' do
      mug = Mug.create! name: 'test'
      mug2 = Mug.create! name: 'test 2'
      Mug.create! name: 'test 3'
      handle = Handle.create! mug_id: mug.id
      if mug != handle.mug
        puts " #{mug.class.hash} vs #{handle.mug.class.hash} --#{Mug.hash}"
      end
      expect(handle.mug).to eq mug

      handle.mug_id = mug2.id
      expect(handle.mug).to eq mug2
    end
  end



  context 'polymorphic' do
    it 'should define with just name' do
      undefine_class :Foo
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, item_id: Integer, item_type: String
          belongs_to :item, polymorphic: true
        end
      end.not_to raise_error
    end

    context 'values' do
      before(:all) do
        undefine_class :Foo, :Bar
        class Bar < MemoryRecord::Base
          attributes id: Integer, name: String
        end
        class Foo < MemoryRecord::Base;
          attributes id: Integer, item_id: Integer, item_type: String
          belongs_to :item, polymorphic: true
        end
      end

      it 'should set proper values' do
        bar = Bar.create! name: 'test'
        foo = Foo.create! item: bar
        expect(foo.item_id).to eq bar.id
        expect(foo.item_type).to eq 'Bar'
      end

      it 'should load proper values' do
        bar = Bar.create! name: 'test'
        bar2 = Bar.create! name: 'test 2'
        Bar.create! name: 'test 3'
        foo = Foo.create! item_id: bar.id, item_type: 'Bar'
        expect(foo.item_id).to eq bar.id
        expect(foo.item).to eq bar

        foo.item_id = bar2.id
        expect(foo.item).to eq bar2
      end
    end
  end
end
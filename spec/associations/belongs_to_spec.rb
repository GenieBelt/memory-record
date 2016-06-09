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
      undefine_class :Foo, :Bar
      class Bar < MemoryRecord::Base
        attributes id: Integer, name: String
      end
      class Foo < MemoryRecord::Base;
        attributes id: Integer, bar_id: Integer
        belongs_to :bar
      end
    end

    it 'should set proper values' do
      bar = Bar.create! name: 'test'
      foo = Foo.create! bar: bar
      expect(foo.bar_id).to eq bar.id
      puts "[3] #{Bar.hash}"
    end

    it 'should load proper values' do
      bar = Bar.create! name: 'test'
      bar2 = Bar.create! name: 'test 2'
      Bar.create! name: 'test 3'
      foo = Foo.create! bar_id: bar.id
      if bar != foo.bar
        puts " #{bar.class.hash} vs #{foo.bar.class.hash} --#{Bar.hash}"
      end
      expect(foo.bar).to eq bar

      foo.bar_id = bar2.id
      expect(foo.bar).to eq bar2
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
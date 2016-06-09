require 'spec_helper'
require 'memory_record/base'

describe 'belongs_to association' do

  context 'define on model' do
    it 'should define with just name' do
      undefine_class :Foo
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, bar_id: Integer
          belongs_to :bar
        end
      end.not_to raise_error
    end

    it 'should define with fk' do
      undefine_class :Foo
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, custom_bar_id: Integer
          belongs_to :bar, foreign_key: :custom_bar_id
        end
      end.not_to raise_error
    end
  end

  it 'should load proper values' do
    undefine_class :Foo
    undefine_class :Bar
    class Bar < MemoryRecord::Base
      attributes id: Integer, name: String
    end
    class Foo < MemoryRecord::Base;
      attributes id: Integer, bar_id: Integer
      belongs_to :bar
    end

    bar = Bar.create! name: 'test'
    foo = Foo.create! bar: bar
    expect(foo.bar_id).to eq bar.id
  end

end
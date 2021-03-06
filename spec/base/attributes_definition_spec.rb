require 'spec_helper'
require 'memory_record/base'

describe 'Base -> Attributes Definition' do

  before(:each) do
    undefine_class :Foo
    class Foo < MemoryRecord::Base; end
  end

  it 'should define attributes methods' do
    Foo.class_eval do
      attributes :id, :bar
    end

    expect(Foo.new).to respond_to :id
    expect(Foo.new).to respond_to :id=
    expect(Foo.new).to respond_to :bar=
    expect(Foo.new).to respond_to :bar=
  end

  it 'should define attributes methods with types' do
    Foo.class_eval do
      attributes id: Integer, bar: Symbol
    end

    expect(Foo.new).to respond_to :id
    expect(Foo.new).to respond_to :id=
    expect(Foo.new).to respond_to :bar=
    expect(Foo.new).to respond_to :bar=

    expect(Foo.attributes_types[:id]).to eq Integer
    expect(Foo.attributes_types[:bar]).to eq Symbol
  end

  it 'should return proper id if different primary key is defined' do
    Foo.class_eval do
      attributes foo_id: Integer
      def self.primary_key
        :foo_id
      end
    end

    expect(Foo.new).to respond_to :id
    expect(Foo.new).to respond_to :id=

    foo = Foo.new foo_id: 1
    expect(foo.id).to eq 1
    foo.id = 2
    expect(foo.foo_id).to eq 2
  end

  it 'should return proper attributes names list' do
    Foo.class_eval do
      attributes :foo_id, :test
    end

    expect(Foo.new.attribute_names).to include 'foo_id', 'test'
  end

  it 'should return attributes list for serializations' do
    Foo.class_eval do
      attributes :foo_id, :test
    end

    expect(Foo.new.attributes.keys).to include 'foo_id', 'test'
    expect(Foo.new.attributes.values.compact).to be_empty
  end
end
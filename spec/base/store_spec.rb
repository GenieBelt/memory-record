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
    expect(Foo.next_id).to eq 2
  end

  it 'should be able to save new object' do
    foo = Foo.new bar: :test
    expect(foo.new_record?).to be_truthy
    expect(foo.save).to be_truthy
    expect(foo.id).to be
    expect(foo.persisted?).to eq true
    expect(foo.new_record?).to eq false
  end

  it 'should create object' do
    foo = Foo.create bar: :test
    expect(foo.id).to be
    expect(foo.persisted?).to eq true
    expect(foo.new_record?).to eq false
  end

  it 'should return false while saving not valid' do
    Foo.class_eval do
      attributes :x
      validates :x, presence: true
    end
    foo = Foo.new bar: :test
    expect(foo.new_record?).to be_truthy
    expect(foo.save).to be_falsey
    expect(foo.id).to be_nil
    expect(foo.persisted?).to eq false
    expect(foo.new_record?).to eq true
  end
end
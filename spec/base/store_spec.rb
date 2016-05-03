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

  context 'multi-threaded' do
    it 'should keep local changes per tread' do
      foo = Foo.new bar: :test
      foo.save
      thread_bar = nil
      foo.bar = :thread1
      thread = Thread.new { thread_bar = foo.bar; foo.bar = :thread2 }
      thread.join
      expect(thread_bar).to eq :test
      expect(foo.bar).to eq :thread1
    end
  end

  context 'get methods' do
    it 'should find existing object' do
      foo = Foo.new bar: :test
      foo.save
      expect(Foo.find(foo.id)).to eq foo
    end

    it 'should raise error if object not found' do
      expect { Foo.find(:x) }.to raise_error MemoryRecord::RecordNotFound
    end
  end
end
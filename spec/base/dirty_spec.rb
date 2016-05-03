require 'spec_helper'
require 'memory_record/base'

describe 'Base dirty attributes' do

  before(:each) do
    undefine_class :Foo
    class Foo < MemoryRecord::Base
      attributes :id, :bar
    end
  end

  it 'should create changes fields' do
    foo = Foo.new bar: :test
    expect(foo.changed?).to be_truthy
    expect(foo.bar_changed?).to be_truthy
    expect(foo.bar_change).to eq [nil, :test]
    expect(foo.changes.keys).to include 'bar'
  end

  it 'should clean changes on save' do
    foo = Foo.new bar: :test
    foo.save!
    expect(foo.changed?).to be_falsey
    expect(foo.bar_changed?).to be_falsey
    expect(foo.bar_change).to eq nil
    expect(foo.changes.keys).to be_empty
  end

  it 'can rollback changes' do
    foo = Foo.new bar: :test
    foo.save!
    foo.bar = :foobar
    expect(foo.changed?).to be_truthy
    expect(foo.bar_changed?).to be_truthy
    expect(foo.bar_change).to eq [:test, :foobar]
    foo.rollback!
    expect(foo.bar).to eq :test
    expect(foo.changed?).to be_falsey
    expect(foo.bar_changed?).to be_falsey
    expect(foo.bar_change).to eq nil
    expect(foo.changes.keys).to be_empty
  end

  it 'should clean changes on reload' do
    foo = Foo.new bar: :test
    foo.save!
    foo.bar = :foobar
    expect(foo.changed?).to be_truthy
    expect(foo.bar_changed?).to be_truthy
    expect(foo.bar_change).to eq [:test, :foobar]
    foo.reload!
    expect(foo.bar).to eq :test
    expect(foo.changed?).to be_falsey
    expect(foo.bar_changed?).to be_falsey
    expect(foo.bar_change).to eq nil
    expect(foo.changes.keys).to be_empty
  end
end
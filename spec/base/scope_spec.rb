require 'spec_helper'
require 'memory_record/base'

describe 'Base -> scoping' do

  before(:each) do
    undefine_class :Foo
    class Foo < MemoryRecord::Base
      attributes :id, :bar
    end
  end


  it 'should create scope class' do
    Foo.send :scope_class
    expect(defined? Foo::SearchScope).to be_truthy
  end

  it 'should return scope instance on where' do
    expect(Foo.where(id: 1)).to be_a MemoryRecord::SearchScope
  end

  it 'should search when where is set' do
    foos = []
    id = 1
    5.times do |i|
      id += i
      foos << Foo.create!(id: id, bar: rand(100))
    end

    expect(Foo.where(id: foos.map(&:id))).to eq foos
    expect(Foo.where(id: 1).all).to include foos.first
    expect(Foo.where(id: (1..3)).all).to include foos[0], foos[1]
    expect(Foo.where(id: (1..3)).all).not_to include foos[2], foos[3], foos[4]
  end

  it 'should create scope' do
    Foo.scope :test_scope, ->(name){ where(bar: name) }
    expect(Foo.respond_to? :test_scope).to be_truthy
    expect(Foo::SearchScope.new.respond_to? :test_scope)
  end
end
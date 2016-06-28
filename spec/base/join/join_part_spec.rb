require 'spec_helper'
require 'memory_record/search_scope/joins'

describe 'JoinPart' do

  class AJoinPartTest
    attr_accessor :name, :scope
  end
  class BJoinPartTest
    attr_accessor :foo, :bar
  end
  class CJoinPartTest
    attr_accessor :name, :foo
  end

  it 'should respond to base methods' do
    a = AJoinPartTest.new
    a.name = 'bla bla'
    a.scope = :scope_symbol
    b = BJoinPartTest.new
    join_part = MemoryRecord::JoinPart.new :a, a: a, b: b
    expect(join_part.name).to eq 'bla bla'
    expect(join_part.scope).to eq :scope_symbol
  end

  it 'should be able to marge result' do
    a = AJoinPartTest.new
    a.name = 'bla bla'
    b = BJoinPartTest.new
    c = CJoinPartTest.new
    join_part = MemoryRecord::JoinPart.new :a, a: a, b: b
    expect { join_part.merge(c: c) }.not_to raise_error
    expect(join_part.name).to eq 'bla bla'
    expect(join_part.c).to eq c
  end

  it 'should return second element' do
    a = AJoinPartTest.new
    a.name = 'bla bla'
    a.scope = :scope_symbol
    b = BJoinPartTest.new
    join_part = MemoryRecord::JoinPart.new :a, a: a, b: b
    expect(join_part.b).to eq b
    join_part.b.foo = :b
    expect(b.foo).to eq :b
  end

  it 'should return second element with wired naming' do
    a = AJoinPartTest.new
    a.name = 'bla bla'
    a.scope = :scope_symbol
    b = BJoinPartTest.new
    join_part = MemoryRecord::JoinPart.new :a, a: a, :'test.b' => b
    expect(join_part.send(:'test.b')).to eq b
  end
end
require 'spec_helper'
require 'memory_record/base'

describe 'Base -> Locking' do

  before(:each) do
    undefine_class :Foo
    class Foo < MemoryRecord::Base
      attributes :id, :bar
    end
  end

  it 'should do be able tu unlock not locked object' do
    foo = Foo.new bar: :test
    expect { foo.unlock! }.not_to raise_error
  end

  it 'should lock object' do
    foo = Foo.new bar: :test
    expect { foo.lock! }.not_to raise_error
    expect(foo.locked?).to be_truthy
    expect { foo.unlock! }.not_to raise_error
    expect(foo.locked?).to be_falsey
  end

  it 'should be able run synchronize when locked' do
    foo = Foo.new bar: :test
    a = false
    thread = Thread.new do
      foo.lock!
      foo.send :synchronize do
        puts "synchronized #{foo}"
      end
      foo.unlock!
      a = true
    end
    thread.join(0.5)
    thread.kill
    expect(a).to be_truthy
  end
end
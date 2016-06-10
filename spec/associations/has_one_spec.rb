require 'spec_helper'
require 'memory_record/base'

describe 'has_one association' do

  before(:each) do
    MemoryRecord::Base.main_store.clean_store
  end

  context 'define on model' do
    it 'should define with just name' do
      undefine_class :Foo, :Bar
      class Bar < MemoryRecord::Base
        attributes id: Integer, name: String
        has_one :foo
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
        has_one :foo, foreign_key: :custom_bar_id
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
      undefine_class :Brain, :Person
      class Person < MemoryRecord::Base
        attributes id: Integer, name: String
        has_one :brain
      end
      class Brain < MemoryRecord::Base;
        attributes id: Integer, person_id: Integer
      end
    end

    it 'should set proper values on create' do
      pending 'check rails behaviour and fix it'
      brain = Brain.create!
      person = Person.create! name: 'test', brain: brain
      expect(person.brain).to eq brain
      expect(brain.person_id).to eq person.id
    end

    it 'should set proper values on edit' do
      brain = Brain.create!
      person = Person.create! name: 'test'
      person.brain = brain
      expect(person.brain).to eq brain
      expect(brain.person_id).to eq person.id
    end

    it 'should load proper values' do
      person = Person.create! name: 'test'
      person2 = Person.create! name: 'test 2'
      Person.create! name: 'test 3'
      brain = Brain.create! person_id: person.id
      expect(person.brain).to eq brain
      expect(person2.brain).to be_nil

      brain.person_id = person2.id
      expect(person.reload.brain).to be_nil
      expect(person2.reload.brain).to eq brain
    end
  end



  context 'polymorphic' do
    it 'should define with just name' do
      undefine_class :Foo, :Bar
      expect do
        class Foo < MemoryRecord::Base;
          attributes id: Integer, item_id: Integer, item_type: String
          belongs_to :item, polymorphic: true
        end
        class Bar < MemoryRecord::Base;
          attributes id: Integer, name: String
          has_one :foo, as: :item
        end
      end.not_to raise_error
    end

    context 'values' do
      before(:all) do
        undefine_class :Pub, :Beer
        class Beer < MemoryRecord::Base
          attributes id: Integer, name: String
          has_one :pub, as: :item
        end
        class Pub < MemoryRecord::Base;
          attributes id: Integer, item_id: Integer, item_type: String
          belongs_to :item, polymorphic: true
        end
      end

      it 'should set proper values' do
        beer = Beer.create! name: 'test'
        pub = Pub.create! item: beer
        beer.pub = pub
        expect(pub.item).to eq beer
      end

      it 'should load proper values' do
        beer = Beer.create! name: 'test'
        beer2 = Beer.create! name: 'test 2'
        Beer.create! name: 'test 3'
        pub = Pub.create! item_id: beer.id, item_type: 'Beer'
        expect(beer.pub).to eq pub
        expect(beer2.pub).to be_nil

        pub.item_id = beer2.id
        pub.save!
        expect(Pub.class_store.get_with_fk(:item_id, beer2.id)).to eq [pub]
        expect(Pub.class_store.get_with_fk(:item_id, beer.id)).to eq []
        expect(beer.reload.pub).to be_nil
        expect(beer2.reload.pub).to eq pub
      end
    end
  end
end
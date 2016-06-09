module MemoryRecord
  module Associations
    class AssociationScope #:nodoc:
      def self.scope(association)
        INSTANCE.scope(association)
      end

      def self.create(&block)
        block ||= lambda { |val| val }
        new(block)
      end

      def initialize(value_transformation)
        @value_transformation = value_transformation
      end

      INSTANCE = create

      def scope(association)
        klass = association.klass
        reflection = association.reflection
        scope = klass.unscoped
        owner = association.owner
        #alias_tracker = AliasTracker.create nil, association.klass.store_name, klass.type_caster
        chain_head, chain_tail = get_chain(reflection, association, nil)

        scope.extending! Array(reflection.options[:extend])
        add_constraints(scope, owner, klass, reflection, chain_head, chain_tail)
      end

      def join_type
        :inner_join
      end

      def self.get_bind_values(owner, chain)
        binds = []
        last_reflection = chain.last

        binds << last_reflection.join_id_for(owner)
        if last_reflection.type
          binds << owner.class.base_class.name
        end

        chain.each_cons(2).each do |reflection, next_reflection|
          if reflection.type
            binds << next_reflection.klass.base_class.name
          end
        end
        binds
      end

      protected

      attr_reader :value_transformation

      private

      def last_chain_scope(scope, reflection, owner, association_klass)
        join_keys = reflection.join_keys(association_klass)
        key = join_keys.key
        foreign_key = join_keys.foreign_key

        value = transform_value(owner[foreign_key])
        scope = scope.where( key => value )

        if reflection.type
          polymorphic_type = transform_value(owner.class.base_class.name)
          scope = scope.where( reflection.type => polymorphic_type )
        end

        scope
      end

      def transform_value(value)
        value_transformation.call(value)
      end

      def next_chain_scope(scope, reflection, association_klass, foreign_table, next_reflection)
        join_keys = reflection.join_keys(association_klass)
        key = join_keys.key
        foreign_key = join_keys.foreign_key

        constraint = table[key].eq(foreign_table[foreign_key])

        if reflection.type
          value = transform_value(next_reflection.klass.base_class.name)
          scope = scope.where(table.name => { reflection.type => value })
        end

        scope = scope.joins(join(foreign_table, constraint))
      end

      class ReflectionProxy < SimpleDelegator # :nodoc:
        attr_accessor :next
        attr_reader :alias_name

        def initialize(reflection, alias_name)
          super(reflection)
          @alias_name = alias_name
        end

        def all_includes; nil; end
      end

      def get_chain(reflection, association, tracker)
        name = reflection.name
        runtime_reflection = Reflection::RuntimeReflection.new(reflection, association)
        previous_reflection = runtime_reflection
        reflection.chain.drop(1).each do |refl|
          #alias_name = tracker.aliased_table_for(refl.store_name, refl.alias_candidate(name))
          alias_name = nil
          proxy = ReflectionProxy.new(refl, alias_name)
          previous_reflection.next = proxy
          previous_reflection = proxy
        end
        [runtime_reflection, previous_reflection]
      end

      def add_constraints(scope, owner, association_klass, refl, chain_head, chain_tail)
        owner_reflection = chain_tail
        scope = last_chain_scope(scope, owner_reflection, owner, association_klass)

        reflection = chain_head
        loop do
          break unless reflection
          #table = reflection.alias_name

          unless reflection == chain_tail
            next_reflection = reflection.next
            foreign_table = next_reflection.alias_name
            #scope = next_chain_scope(scope, table, reflection, association_klass, foreign_table, next_reflection)
            scope = next_chain_scope(scope, reflection, association_klass, foreign_table, next_reflection)
          end

          # Exclude the scope of the association itself, because that
          # was already merged in the #scope method.
          reflection.constraints.each do |scope_chain_item|
            item  = eval_scope(reflection.klass, scope_chain_item, owner)

            if scope_chain_item == refl.scope
              scope.merge! item
            end
          end

          reflection = reflection.next
        end

        scope
      end

      def eval_scope(klass, scope, owner)
        klass.unscoped.instance_exec(owner, &scope)
      end
    end
  end
end

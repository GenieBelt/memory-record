require 'memory_record/logger'
require 'memory_record/base/search_scope'
module MemoryRecord
  module Scope
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def find(id)
        class_store.get(id) || raise(RecordNotFound.new "Cannot find #{name} with id #{id}")
      end

      def with_id(id)
        class_store.get(id)
      end

      def first
        all.first
      end

      # @return [Array<Object>]
      def all
        default_scope.all
      end

      def with_fk(key_name,id)
        scope_class.new(:_with_fk, key_name, id)
      end

      def _all
        class_store.all
      end

      def _with_fk(key_name,id)
        class_store.get_with_fk(key_name, id)
      end

      # @return [Array<Integer>]
      def ids
        default_scope.ids
      end

      # @return [MemoryRecord::SearchScope]
      def where(*args)
        default_scope.where(*args)
      end

      def scope_methods(*names)
        names.each do |name|
          scope_method name
        end
      end

      def scope(name, lambda)
        scope_method name
        scope_class[name] = lambda
      end

      def with_scope(scope)
        old_scope = current_scope
        self.current_scope = scope
        result = yield
        self.current_scope = old_scope
        result
      rescue
        self.current_scope = old_scope
        raise
      end

      protected

      def default_scope
        current_scope || scope_class.new
      end

      def current_scope
        Thread.current["#{parent_class}_current_scope"]
      end

      def current_scope=(new_scope)
        Thread.current["#{parent_class}_current_scope"]= new_scope
      end

      def scope_method(name)
        self.class_eval <<-METHOD
def self.#{name}(*args)
  default_scope.#{name}(*args)
end
        METHOD
      end

      def scope_class
        clazz = instance_variable_get :@scope_class
        unless clazz
          define_clazz
        end
        clazz || instance_variable_get(:@scope_class)
      end

      private

      def define_clazz
        scope_name = "#{self}::SearchScope"
        if class_exists? scope_name
          clazz = Object.const_get(scope_name)
          current_class = self
          clazz.class_eval do
            self.base_class = current_class
          end
        else
          if superclass.respond_to?(:scope_class) && superclass.superclass.respond_to?(:scope_class)
            clazz = Class.new(superclass.scope_class)
          else
            clazz = Class.new(SearchScope)
          end
          self.const_set 'SearchScope', clazz
          current_class = self
          clazz.class_eval do
            self.base_class = current_class
          end
          MemoryRecord.logger.debug "Defined #{scope_name} base class is #{current_class}."
        end
        instance_variable_set :@scope_class, Object.const_get(scope_name)
      end

      def class_exists?(class_name)
        klass = Module.const_get(class_name)
        return klass.is_a?(Class)
      rescue NameError
        return false
      end
    end
  end
end


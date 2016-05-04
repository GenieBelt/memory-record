require 'memory_record/logger'
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


      # @return [Array<Object>]
      def all
        default_scope.all
      end

      def _all
        class_store.all
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
        MemoryRecord.logger.debug "Defined #{scope_name} class."
        if class_exists? scope_name
          clazz = Object.const_get(scope_name)
          current_class = self
          clazz.class_eval do
            self.base_class = current_class
          end
          MemoryRecord.logger.debug "Defined #{scope_name} base class is #{current_class}."
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

  class SearchScope
    class << self
      def [](name)
        init_scopes
        @scopes[name]
      end

      def []=(name, lambda)
        init_scopes
        @scopes[name] = lambda
      end

      def all_scopes
        init_scopes
        @scopes
      end

      private

      def init_scopes
        @scopes ||= superclass.respond_to?(:all_scopes) ? superclass.all_scopes : Hash.new
      end
    end

    def to_a
      all
    end

    def ==(other)
      all == other
    end

    def !=(other)
      all != other
    end

    def ===(other)
      all === other
    end

    def eql?(other)
      all.eql? other
    end

    def equal?(other)
      all.equal? other
    end

    def [](index)
      all[index]
    end

    def initialize(*args)
      @base_scope = args if args.any?
      @filters = []
    end


    def where(params=nil)
      return self unless params
      params.each do |key, value|
        if value.kind_of? Range
          add_filter ->(object){ object.send(key) >= value.first &&  object.send(key) <= value.last }
        elsif value.kind_of? Array
          add_filter ->(object){ value.include?(object.send(key)) }
        elsif value.kind_of? Hash
          add_filter ->(object){ object.send(key).where(value).any? }
        else
          add_filter ->(object){ object.send(key) == value }
        end
      end
      self
    end

    def not(params)
      return self unless params
      params.each do |key, value|
        if value.kind_of? Range
          add_filter ->(object){ object.send(key) < value.first ||  object.send(key) > value.last }
        elsif value.kind_of? Array
          add_filter ->(object){ !(value.include?(object.send(key))) }
        elsif value.kind_of? Hash
          add_filter ->(object){ object.send(key).where(value).empty? }
        else
          add_filter ->(object){ object.send(key) != value }
        end
      end
      self
    end

    def all
      apply_limit(apply_filters)
    end

    def ids
      all.map(&:id)
    end

    def find(id)
      where(id: id).all.first || raise(RecordNotFound.new "Cannot find #{base_class.name} with id #{id}")
    end

    def limit(new_limit)
      @limit = new_limit
      self
    end

    def add_filter(filter)
      @filters << filter
      self
    end

    def method_missing(name, *args)
      if self.class[name]
        MemoryRecord.logger.debug "Calling scope #{name} with #{args}!\nBefore scope #{ids}"
        self.class.base_class.with_scope self do
          self.class[name].call(*args)
        end
      elsif all.respond_to? name
        all.send(name, *args)
      elsif self.class.base_class.respond_to?(name)
        self.class.base_class.with_scope self do
          MemoryRecord.logger.debug "Missing method #{name} one scope!"
          self.class.base_class.send(name, *args)
        end
      else
        self.class.base_class.send(name, *args)
      end
    end

    def respond_to?(method)
      super || !!self.class[method] || all.respond_to?(method) || self.base_class.respond_to?(method)
    end

    private

    def base_scope
      if @base_scope
        base_class.send(*@base_scope)
      else
        base_class._all
      end
    end

    def apply_filters
      if @filters.empty?
        base_scope
      else
        base_scope.select do |object|
          apply_on_object(object)
        end
      end
    end

    def apply_limit(scope)
      @limit ? scope.take(@limit) : scope
    end

    def apply_on_object(object)
      @filters.each do |filter|
        return false unless filter.call(object)
      end
      true
    end

    def base_class
      self.class.base_class
    end

    class << self
      def base_class
        @base_class
      end

      private

      def base_class=(clazz)
        @base_class = clazz
      end
    end
  end

  module ArrayExtensions
    def ==(other)
      if other.is_a? ::MemoryRecord::SearchScope
        super other.to_a
      else
        super
      end
    end
  end

  ::Array.send :prepend, MemoryRecord::ArrayExtensions
end


require 'memory_record/logger'
module MemoryRecord
  class SearchScope
    attr_accessor :extending_values
    private :extending_values, :extending_values=

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
      @extending_values = []
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

    def records
      all
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

    def _filters
      @filters
    end

    def _add_filters(filters)
      @filters += filters
      self
    end

    def merge(scope)
      self.class.new(self)._add_filters(scope._filters)
    end

    def method_missing(name, *args)
      if self.class[name]
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

    def extending!(*modules, &block) # :nodoc:
      modules << Module.new(&block) if block
      modules.flatten!

      self.extending_values += modules
      extend(*extending_values) if extending_values.any?

      self
    end

    private

    def base_scope
      if @base_scope && @base_scope.first && @base_scope.first.kind_of?(self.class)
        @base_scope.first.all
      elsif @base_scope
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


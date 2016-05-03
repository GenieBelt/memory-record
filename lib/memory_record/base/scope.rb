module MemoryRecord
  module Scope
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # @return [MemoryRecord::SearchScope]
      def where(*args)
        scope_class.new.where(*args)
      end

      protected

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
        unless class_exists? scope_name
          current_class = self
          clazz = Class.new(SearchScope)
          self.const_set 'SearchScope', clazz
          clazz.class_eval do
            self.base_class = current_class
          end
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
    def ==(other)
      all == other
    end

    def eql?(other)
      all.eql? other
    end

    def equal?(other)
      all.equal? other
    end

    def <=>(other)
      all <=> other
    end

    def [](index)
      all[index]
    end

    def initialize(*args)
      @base_scope = args if args.any?
    end


    def where(params)
      params.each do |key, value|
        if value.kind_of? Range
          add_filter ->(object){ object.send(key) >= value.first &&  object.send(key) <= value.last }
        elsif value.kind_of? Array
          add_filter ->(object){ object.send(key).is_a?(Array) ? object.send(key) == value : value.include?(object.send(key)) }
        elsif value.kind_of? Hash
          add_filter ->(object){ object.send(key).where(value).any? }
        else
          add_filter ->(object){ object.send(key) == value }
        end
      end
      self
    end

    def all
      apply_filters
    end

    def add_filter(filter)
      @filters ||=[]
      @filters << filter
    end

    def method_missing(*args)
      all.send(*args)
    end

    private

    def base_scope
      if @base_scope
        base_class.send(*@base_scope)
      else
        base_class.all
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
end
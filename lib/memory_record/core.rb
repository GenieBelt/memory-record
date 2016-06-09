module MemoryRecord
  module Core
    module ClassMethods
      def inherited(child_class) #:nodoc:
        child_class.initialize_generated_modules
        super
      end

      def initialize_generated_modules # :nodoc:
        generated_association_methods
      end

      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end
    end

    def initialize(params=nil)
      @attribute_list = Hash.new
      @mutex = Mutex.new
      init_internals
      initialize_internals_callback

      assign_attributes params if params

      yield self if block_given?
      #_run_initialize_callbacks
    end

    def init_internals
      @readonly                 = false
      @destroyed                = false
      @marked_for_destruction   = false
      @destroyed_by_association = nil
      @new_record               = true
    end

    def initialize_internals_callback
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end

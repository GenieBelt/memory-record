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

      def primary_key
        @primary_key || :id
      end

      def primary_key=(new_pk)
        @primary_key = new_pk
      end
    end

    def initialize(params=nil)
      @attribute_list = Hash.new
      @mutex = Mutex.new
      init_internals
      initialize_internals_callback
      self.temp_attribute_list = Hash.new

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

    # Returns true if +comparison_object+ is the same exact object, or +comparison_object+
    # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
    #
    # Note that new records are different from any other record by definition, unless the
    # other record is the receiver itself. Besides, if you fetch existing records with
    # +select+ and leave the ID out, you're on your own, this predicate will return false.
    #
    # Note also that destroying a record preserves its ID in the model instance, so deleted
    # models are still comparable.
    def ==(comparison_object)
      super ||
          comparison_object.instance_of?(self.class) &&
              !id.nil? &&
              comparison_object.id == id
    end
    alias :eql? :==

    # Allows sort on objects
    def <=>(other_object)
      if other_object.is_a?(self.class)
        self.to_key <=> other_object.to_key
      else
        super
      end
    end

    def to_key
      id
    end

    def self.included(base)
      base.extend ClassMethods
    end

    protected

    def id_key
      key = nil
      if self.class.respond_to? :id_key
        key = self.class.id_key
      elsif self.class.respond_to? :primary_key
        key = self.class.primary_key
      end
      key || :id
    end
  end
end

module MemoryRecord

  # = Memory Record Errors
  #
  # Generic Memory Record exception class.
  class MemoryRecordError < StandardError
  end

  # Raised when the single-table inheritance mechanism fails to locate the subclass
  # (for example due to improper usage of column that
  # {MemoryRecord::Base.inheritance_column}[rdoc-ref:ModelSchema::ClassMethods#inheritance_column]
  # points to).
  class SubclassNotFound < MemoryRecordError
  end

  # Raised when an object assigned to an association has an incorrect type.
  #
  #   class Ticket < MemoryRecord::Base
  #     has_many :patches
  #   end
  #
  #   class Patch < MemoryRecord::Base
  #     belongs_to :ticket
  #   end
  #
  #   # Comments are not patches, this assignment raises AssociationTypeMismatch.
  #   @ticket.patches << Comment.new(content: "Please attach tests to your patch.")
  class AssociationTypeMismatch < MemoryRecordError
  end

  # Raised when unserialized object's type mismatches one specified for serializable field.
  class SerializationTypeMismatch < MemoryRecordError
  end

  # Raised when Memory Record cannot find a record by given id or set of ids.
  class RecordNotFound < MemoryRecordError
    attr_reader :model, :primary_key, :id

    def initialize(message = nil, model = nil, primary_key = nil, id = nil)
      @primary_key = primary_key
      @model = model
      @id = id

      super(message)
    end
  end

  # Raised by {MemoryRecord::Base#save!}[rdoc-ref:Persistence#save!] and
  # {MemoryRecord::Base.create!}[rdoc-ref:Persistence::ClassMethods#create!]
  # methods when a record is invalid and can not be saved.
  class RecordNotSaved < MemoryRecordError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end

  class RecordNotCommitted <  MemoryRecordError; end

  # Raised by {MemoryRecord::Base#destroy!}[rdoc-ref:Persistence#destroy!]
  # when a call to {#destroy}[rdoc-ref:Persistence#destroy!]
  # would return false.
  #
  #   begin
  #     complex_operation_that_internally_calls_destroy!
  #   rescue MemoryRecord::RecordNotDestroyed => invalid
  #     puts invalid.record.errors
  #   end
  #
  class RecordNotDestroyed < MemoryRecordError
    attr_reader :record

    def initialize(message = nil, record = nil)
      @record = record
      super(message)
    end
  end

  # Superclass for all database execution errors.
  #
  # Wraps the underlying database error as +cause+.
  class StatementInvalid < MemoryRecordError

    def initialize(message = nil)
      super(message || $!.try(:message))
    end
  end

  # Raised when a record cannot be inserted because it would violate a uniqueness constraint.
  class RecordNotUnique < StatementInvalid
  end

  # Raised when a record cannot be inserted or updated because it references a non-existent record.
  class InvalidForeignKey < StatementInvalid
  end

  # Raised when a record cannot be inserted or updated because a value too long for a column type.
  class ValueTooLong < StatementInvalid
  end

  # Raised when number of bind variables in statement given to +:condition+ key
  # (for example, when using {MemoryRecord::Base.find}[rdoc-ref:FinderMethods#find] method)
  # does not match number of expected values supplied.
  #
  # For example, when there are two placeholders with only one value supplied:
  #
  #   Location.where("lat = ? AND lng = ?", 53.7362)
  class PreparedStatementInvalid < MemoryRecordError
  end


  # Raised on attempt to save stale record. Record is stale when it's being saved in another query after
  # instantiation, for example, when two users edit the same wiki page and one starts editing and saves
  # the page before the other.
  #
  # Read more about optimistic locking in MemoryRecord::Locking module
  # documentation.
  class StaleObjectError < MemoryRecordError
    attr_reader :record, :attempted_action

    def initialize(record = nil, attempted_action = nil)
      if record && attempted_action
        @record = record
        @attempted_action = attempted_action
        super("Attempted to #{attempted_action} a stale object: #{record.class.name}.")
      else
        super("Stale object error.")
      end
    end

  end

  # Raised when association is being configured improperly or user tries to use
  # offset and limit together with
  # {MemoryRecord::Base.has_many}[rdoc-ref:Associations::ClassMethods#has_many] or
  # {MemoryRecord::Base.has_and_belongs_to_many}[rdoc-ref:Associations::ClassMethods#has_and_belongs_to_many]
  # associations.
  class ConfigurationError < MemoryRecordError
  end

  # Raised on attempt to update record that is instantiated as read only.
  class ReadOnlyRecord < MemoryRecordError
  end

  # {MemoryRecord::Base.transaction}[rdoc-ref:Transactions::ClassMethods#transaction]
  # uses this exception to distinguish a deliberate rollback from other exceptional situations.
  # Normally, raising an exception will cause the
  # {.transaction}[rdoc-ref:Transactions::ClassMethods#transaction] method to rollback
  # the database transaction *and* pass on the exception. But if you raise an
  # MemoryRecord::Rollback exception, then the database transaction will be rolled back,
  # without passing on the exception.
  #
  # For example, you could do this in your controller to rollback a transaction:
  #
  #   class BooksController < ActionController::Base
  #     def create
  #       Book.transaction do
  #         book = Book.new(params[:book])
  #         book.save!
  #         if today_is_friday?
  #           # The system must fail on Friday so that our support department
  #           # won't be out of job. We silently rollback this transaction
  #           # without telling the user.
  #           raise MemoryRecord::Rollback, "Call tech support!"
  #         end
  #       end
  #       # MemoryRecord::Rollback is the only exception that won't be passed on
  #       # by MemoryRecord::Base.transaction, so this line will still be reached
  #       # even on Friday.
  #       redirect_to root_url
  #     end
  #   end
  class Rollback < MemoryRecordError
    def initialize
      super 'Rollback'
    end
  end

  # Raised when attribute has a name reserved by Memory Record (when attribute
  # has name of one of Memory Record instance methods).
  class DangerousAttributeError < MemoryRecordError
  end

  # Raised when unknown attributes are supplied via mass assignment.
  # UnknownAttributeError = ActiveModel::UnknownAttributeError

  # Raised when an error occurred while doing a mass assignment to an attribute through the
  # {MemoryRecord::Base#attributes=}[rdoc-ref:AttributeAssignment#attributes=] method.
  # The exception has an +attribute+ property that is the name of the offending attribute.
  class AttributeAssignmentError < MemoryRecordError
    attr_reader :exception, :attribute

    def initialize(message = nil, exception = nil, attribute = nil)
      super(message)
      @exception = exception
      @attribute = attribute
    end
  end

  # Raised when there are multiple errors while doing a mass assignment through the
  # {MemoryRecord::Base#attributes=}[rdoc-ref:AttributeAssignment#attributes=]
  # method. The exception has an +errors+ property that contains an array of AttributeAssignmentError
  # objects, each corresponding to the error while assigning to an attribute.
  class MultiparameterAssignmentErrors < MemoryRecordError
    attr_reader :errors

    def initialize(errors = nil)
      @errors = errors
    end
  end

  # Raised when a primary key is needed, but not specified in the schema or model.
  class UnknownPrimaryKey < MemoryRecordError
    attr_reader :model

    def initialize(model = nil, description = nil)
      if model
        message = "Unknown primary key for table #{model.table_name} in model #{model}."
        message += "\n#{description}" if description
        @model = model
        super(message)
      else
        super("Unknown primary key.")
      end
    end
  end

  # Raised when a relation cannot be mutated because it's already loaded.
  #
  #   class Task < MemoryRecord::Base
  #   end
  #
  #   relation = Task.all
  #   relation.loaded? # => true
  #
  #   # Methods which try to mutate a loaded relation fail.
  #   relation.where!(title: 'TODO')  # => MemoryRecord::ImmutableRelation
  #   relation.limit!(5)              # => MemoryRecord::ImmutableRelation
  class ImmutableRelation < MemoryRecordError
  end

  # IrreversibleOrderError is raised when a relation's order is too complex for
  # +reverse_order+ to automatically reverse.
  class IrreversibleOrderError < MemoryRecordError
  end
end

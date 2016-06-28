module MemoryRecord
  class JoinResult < Array
    attr_reader :base_name

    def initialize(base_name, *args)
      @base_name = base_name
      super *args
    end
  end
end

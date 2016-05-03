module MemoryRecord
  module Locking
    def lock!
      @mutex.lock unless @mutex.owned?
    end

    def unlock!
      @mutex.unlock if @mutex.owned?
    end

    def locked?
      @mutex.owned?
    end

    protected

    def synchronize
      if @mutex.owned?
        yield
      else
        @mutex.synchronize do
          yield
        end
      end
    end
  end
end
module MemoryRecord
  def self.logger
    @logger ||= ::Logger.new(STDOUT)
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  module Logger
    def logger
      MemoryRecord.logger
    end
  end
end
class AttributedObject
  def initialize(args)
    if args
      self.class.send :attr_accessor, *args.keys
      args.each do |key, value|
        self.send "#{key}=", value
      end
    end
  end
end
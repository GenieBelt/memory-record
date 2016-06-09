module ClassSupport
  def undefine_class(*names)
    names.each do |name|
      if Object.constants.include?(name.to_sym)
        Object.send(:remove_const, name.to_sym)
      end
    end
  end
end
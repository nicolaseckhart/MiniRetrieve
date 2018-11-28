class FreqList
  attr_accessor :list

  def initialize
    @list = {}
  end

  def append(identifier)
    @list[identifier] = 0 if @list[identifier].nil?
  end

  def increment_freq(identifier)
    @list[identifier] += 1
  end

  def to_s
    @list.to_s
  end
end

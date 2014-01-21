class Integer

  def prime?
    return false if self <= 1
    2.upto(pred).all? { |possible_divisor| not divisable_by?(possible_divisor) }
  end

  def prime_factors
    return [] if self == 1
    prime_factor = 2.upto(abs).find do |possible_factor|
      divisable_by?(possible_factor)
    end

    [prime_factor] + abs.div(prime_factor).prime_factors
  end

  def harmonic
    1.upto(self).map { |number| number.to_r**-1 }.reduce(&:+)
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end

  private

  def divisable_by?(what)
    remainder(what).zero?
  end
end

class Array

  def frequencies
    Hash[map { |element| [element, count(element)] }]
  end

  def average
    reduce(:+) / size.to_f
  end

  def drop_every(n)
    reject { |i| index(i).next.divisable_by?(n) }
  end

  def combine_with(other)
    combined = []
    the_greater_size = (size > other.size) ? size : other.size
    0.upto(the_greater_size.pred).each do |i|
      combined += what_to_append(other, i)
    end
    combined
  end

  private

  def what_to_append(other, index)
    if size > index and other.size > index
      [self[index], other[index]]
    else
      size <= index ? [other[index]] : [self[index]]
    end
  end
end
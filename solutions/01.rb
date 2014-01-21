class Integer

  def prime?
    return false if self <= 1
    2.upto(pred).all? { |possible_divisor| not divisable_by?(possible_divisor) }
  end

  def prime_factors
    pfs_repeating = []
    pfs = (2..abs.pred).select { |i| divisable_by?(i) and i.prime? }
    pfs.each { |pf| pfs_repeating += Array.new(times_to_repeat(pf), pf) }
    pfs_repeating
  end

  def harmonic
    (1..self).reduce { |so_far, i| so_far + i.to_r**-1 } #TODO test with 2.1
  end

  def digits
    abs.to_s.split('').map(&:to_i)
  end

  private

  def divisable_by?(what)
    remainder(what).zero?
  end

  def times_to_repeat(prime_factor)
    number = self
    count = 0
    while number.divisable_by?(prime_factor)
      number /= prime_factor
      count += 1
    end
    count
  end

end

class Array

  def frequencies
    result = {}
    each { |element| result[element] = result[element].to_i.next }
    result
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
    (0..the_greater_size.pred).each { |i| combined += what_to_append(other, i) }
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
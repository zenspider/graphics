##
# Integer extensions for graphics

class Integer
  ##
  # Calculate a random chance using easy notation: 1 =~ 50 :: 1 in 50 chance

  def =~ n #
    rand(n) <= (self - 1)
  end
end

##
# Numeric extensions for graphics

class Numeric
  ##
  # Is M close to N within a certain delta?

  def close_to? n, delta = 0.01
    (self - n).abs < delta
  end

  ##
  # Normalize a number to be within 0...360

  def degrees
    self % 360
  end

  ##
  # I am honestly befuddled by this code, and I wrote it.
  #
  # I should probably remove it and start over.
  #
  # Consider this method private, even tho it is in use by the demos.

  def relative_angle n, max
    delta_cw = (self - n).degrees
    delta_cc = (n - self).degrees

    return if delta_cc < 0.1 || delta_cw < 0.1

    if delta_cc.abs < max then
      delta_cc
    elsif delta_cw.close_to? 180 then
      [-max, max].sample
    elsif delta_cw < delta_cc then
      -max
    else
      max
    end
  end
end

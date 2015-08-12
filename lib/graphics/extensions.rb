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
    (self < 0 ? self + 360 : self) % 360
  end

  ##
  # I am honestly befuddled by this code, and I wrote it.
  #
  # I should probably remove it and start over.
  #
  # Consider this method private, even tho it is in use by the demos.

  def relative_angle n, max
    deltaCW = (self - n).degrees
    deltaCC = (n - self).degrees

    return if deltaCC < 0.1 || deltaCW < 0.1

    if deltaCC.abs < max then
      deltaCC
    elsif deltaCW.close_to? 180 then
      [-max, max].sample
    elsif deltaCW < deltaCC then
      -max
    else
      max
    end
  end
end

class Integer
  def =~ n # 1 =~ 50 :: 1 in 50 chance
    rand(n) <= (self - 1)
  end
end

class Numeric
  def close_to? n, delta = 0.01
    (self - n).abs < delta
  end

  def degrees
    (self < 0 ? self + 360 : self) % 360
  end

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

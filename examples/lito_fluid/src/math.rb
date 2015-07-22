module ExclusiveBetween
  refine Float do
    ##
    # A floating-point friendly `between?` function that excludes
    # the lower bound.
    # Equivalent to `min < x <= max`
    ##
    def xbetween? min, max
      min < self && self <= max
    end
  end
end

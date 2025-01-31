class PointCalculationStrategy
  def calculate_points(asked_tricks, tricks_made)
    if tricks_made == asked_tricks
      10 + tricks_made * 2
    else
      tricks_made
    end
  end
end

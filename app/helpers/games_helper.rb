module GamesHelper
  def bid_options(max:, forbidden: nil)
    (0..max).map do |n|
      label = n.to_s
      label += " ✗" if n == forbidden
      [label, n]
    end
  end
end

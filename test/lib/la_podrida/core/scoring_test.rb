require_relative "../test_helper"

module LaPodrida
  module Core
    class ScoringTest < LaPodrida::TestCase
      test "match with zero tricks" do
        assert_equal 10, Scoring.points(predicted: 0, actual: 0)
      end

      test "match with tricks" do
        assert_equal 12, Scoring.points(predicted: 1, actual: 1)
        assert_equal 14, Scoring.points(predicted: 2, actual: 2)
        assert_equal 20, Scoring.points(predicted: 5, actual: 5)
      end

      test "mismatch returns actual tricks" do
        assert_equal 0, Scoring.points(predicted: 3, actual: 0)
        assert_equal 2, Scoring.points(predicted: 0, actual: 2)
        assert_equal 3, Scoring.points(predicted: 5, actual: 3)
      end

      test "nil predicted returns nil" do
        assert_nil Scoring.points(predicted: nil, actual: 3)
      end

      test "nil actual returns nil" do
        assert_nil Scoring.points(predicted: 3, actual: nil)
      end

      test "both nil returns nil" do
        assert_nil Scoring.points(predicted: nil, actual: nil)
      end
    end
  end
end

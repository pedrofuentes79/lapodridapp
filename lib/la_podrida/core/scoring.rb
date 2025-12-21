module LaPodrida
  module Core
    # Standard La Podrida scoring:
    # - Match (predicted == actual): 10 + (actual * 2)
    # - Mismatch: actual tricks only
    module Scoring
      module_function

      def points(predicted:, actual:)
        return nil if predicted.nil? || actual.nil?

        if predicted == actual
          10 + (actual * 2)
        else
          actual
        end
      end
    end
  end
end

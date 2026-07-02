# rubocop:disable Lint/Void
module Grammars
  Productions = LrExamples::Productions
  class G1 < Productions
    S <= [A, "$"]
    A <= ["(", A, ")", A]
    A <= []
  end

  class G3 < Productions
    S <= [E, "$"]

    E <= [E, "+", B]
    E <= [E, "*", B]
    E <= B

    B <= "0"
    B <= "1"
  end

  class G4 < Productions
    S <= [A, "$"]

    A <= [B, C, D, A]
    A <= "a"

    B <= []
    C <= []
    D <= []
  end
end
# rubocop:enable Lint/Void

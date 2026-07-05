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

  class G5 < Productions
    S <= [A, "$"]
    A <= ["b", B]
    A <= "a"

    B <= ["c", C]
    C <= ["d", A]
  end

  class G5B < Productions
    S <= [A, "$"]
    A <= ["b", B]
    A <= "a"
    A <= "b"

    B <= ["c", C]
    C <= ["d", A]
  end
end
# rubocop:enable Lint/Void

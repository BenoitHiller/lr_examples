# rubocop:disable Lint/Void
module Grammars
  Productions = LrExamples::Productions
  class G1 < Productions
    S <= A
    A <= ["(", A, ")", A]
    A <= []
  end

  class G3 < Productions
    S <= E

    E <= [E, "*", B]
    E <= [E, "+", B]
    E <= B

    B <= "0"
    B <= "1"
  end

  class G4 < Productions
    S <= E

    E <= [F, C, D, E]
    E <= "a"

    F <= []
    C <= []
    D <= []
  end

  class G5 < Productions
    S <= E
    E <= ["f", F]
    E <= "e"

    F <= ["g", G]
    G <= ["h", E]
  end

  # A slight modification of the above specifically to cause the LALR
  # parser to need to use lookahead to distinguish states.
  class G5B < Productions
    S <= E
    E <= ["f", F]
    E <= "e"
    E <= "f"

    F <= ["g", G]
    G <= ["h", E]
  end
end
# rubocop:enable Lint/Void

# rubocop:disable Lint/Void

##
# A set of grammars for use in tests.
#
# They are simply numbered here as they correspond to the numbered
# grammars appearing in the accompanying article.
module Grammars
  Productions = LrExamples::Productions
  ##
  # Extremely minimal grammar
  class G1 < Productions
    S <= A
    A <= ["(", A, ")", A]
    A <= []
  end

  ##
  # A variant of the common basic math grammar used for illustrating
  # parse tables
  class G3 < Productions
    S <= E

    E <= [E, "*", B]
    E <= [E, "+", B]
    E <= B

    B <= "0"
    B <= "1"
  end

  ##
  # The example grammar used by DeRemer and Pennello for illustrating
  # the reads relation.
  class G4 < Productions
    S <= E

    E <= [F, C, D, E]
    E <= "a"

    F <= []
    C <= []
    D <= []
  end

  ##
  # The example grammar used by DeRemer and Pennello for illustrating
  # the includes relation.
  class G5 < Productions
    S <= E
    E <= ["f", F]
    E <= "e"

    F <= ["g", G]
    G <= ["h", E]
  end

  ## A slight modification of the above specifically to cause the LALR
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

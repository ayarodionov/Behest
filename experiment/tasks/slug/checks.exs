s = fn x -> apply(Slug, :slugify, [x]) end

[
  {:core, "Hello World", fn -> s.("Hello World") == "hello-world" end},
  {:core, "an existing slug is unchanged", fn -> s.("already-a-slug") == "already-a-slug" end},
  {:core, "upper case is lowered", fn -> s.("ELIXIR") == "elixir" end},
  {:core, "returns a string", fn -> is_binary(s.("a b")) end},
  {:accents, "Crème Brûlée", fn -> s.("Crème Brûlée") == "creme-brulee" end},
  {:accents, "Ångström", fn -> s.("Ångström") == "angstrom" end},
  {:collapse, "rock & roll", fn -> s.("rock & roll") == "rock-roll" end},
  {:collapse, "a  --  b", fn -> s.("a  --  b") == "a-b" end},
  {:edges, "  Hello!  ", fn -> s.("  Hello!  ") == "hello" end},
  {:edges, "-- dashes --", fn -> s.("-- dashes --") == "dashes" end},
  {:underscore, "snake_case name", fn -> s.("snake_case name") == "snake-case-name" end},
  {:empty, "!!!", fn -> s.("!!!") == "" end},
  {:empty, "empty string", fn -> s.("") == "" end},
  {:digits, "Top 10 Tips", fn -> s.("Top 10 Tips") == "top-10-tips" end},
  {:nonlatin, "Привет world", fn -> s.("Привет world") == "world" end},
  {:apostrophe, "Don't stop", fn -> s.("Don't stop") == "dont-stop" end}
]

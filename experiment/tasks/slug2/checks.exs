s = fn x -> apply(Slug, :slugify, [x]) end

[
  {:core, "Hello World", fn -> s.("Hello World") == "hello-world" end},
  {:core, "an existing slug is unchanged", fn -> s.("already-a-slug") == "already-a-slug" end},
  {:core, "upper case is lowered", fn -> s.("ELIXIR") == "elixir" end},
  {:core, "returns a string", fn -> is_binary(s.("a b")) end},
  {:accents, "Crème Brûlée", fn -> s.("Crème Brûlée") == "creme-brulee" end},
  {:collapse, "a  --  b", fn -> s.("a  --  b") == "a-b" end},
  {:collapse, "wait... what", fn -> s.("wait... what") == "wait-what" end},
  {:edges, "  Hello!  ", fn -> s.("  Hello!  ") == "hello" end},
  {:underscore, "snake_case name", fn -> s.("snake_case name") == "snake_case-name" end},
  {:empty, "!!!", fn -> s.("!!!") == "untitled" end},
  {:empty, "empty string", fn -> s.("") == "untitled" end},
  {:digits, "Top 10 Tips", fn -> s.("Top 10 Tips") == "top-10-tips" end},
  {:nonlatin, "Привет world", fn -> s.("Привет world") == "world" end},
  {:apostrophe, "Don't stop", fn -> s.("Don't stop") == "dont-stop" end},
  {:ampersand, "rock & roll", fn -> s.("rock & roll") == "rock-and-roll" end},
  {:ampersand, "R&D", fn -> s.("R&D") == "r-and-d" end},
  {:maxlen, "cut lands after a whole word",
   fn -> s.("the quick brown fox jumps over the lazy dog") == "the-quick-brown-fox-jumps-over" end},
  {:maxlen, "cut inside a word",
   fn -> s.("aaaaaaaaaa bbbbbbbbbb ccccccccc ddd") == "aaaaaaaaaa-bbbbbbbbbb-cccccccc" end},
  {:maxlen, "cut leaves a hyphen, which is removed",
   fn -> s.("aaaaaaaaaa bbbbbbbbbb ccccccc dd") == "aaaaaaaaaa-bbbbbbbbbb-ccccccc" end}
]

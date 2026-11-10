p = fn x -> apply(Duration, :parse, [x]) end

[
  {:core, "1h30m", fn -> p.("1h30m") == {:ok, 5400} end},
  {:core, "45s", fn -> p.("45s") == {:ok, 45} end},
  {:core, "2h", fn -> p.("2h") == {:ok, 7200} end},
  {:core, "1h2m3s", fn -> p.("1h2m3s") == {:ok, 3723} end},
  {:core, "10m5s", fn -> p.("10m5s") == {:ok, 605} end},
  {:core, "abc is an error", fn -> p.("abc") == :error end},
  {:core, "1h30x is an error", fn -> p.("1h30x") == :error end},
  {:bare, "90", fn -> p.("90") == :error end},
  {:bare, "1h30", fn -> p.("1h30") == :error end},
  {:units, "1d", fn -> p.("1d") == :error end},
  {:units, "500ms", fn -> p.("500ms") == :error end},
  {:order, "30m1h", fn -> p.("30m1h") == :error end},
  {:order, "5s2m", fn -> p.("5s2m") == :error end},
  {:repeat, "1h1h", fn -> p.("1h1h") == :error end},
  {:large, "90m", fn -> p.("90m") == {:ok, 5400} end},
  {:large, "100s", fn -> p.("100s") == {:ok, 100} end},
  {:spaces, "surrounding spaces", fn -> p.(" 1h30m ") == {:ok, 5400} end},
  {:spaces, "1h 30m", fn -> p.("1h 30m") == {:ok, 5400} end},
  {:case, "1H30M", fn -> p.("1H30M") == {:ok, 5400} end},
  {:empty, "empty string", fn -> p.("") == :error end},
  {:empty, "0s", fn -> p.("0s") == {:ok, 0} end},
  {:sign, "-1h", fn -> p.("-1h") == :error end},
  {:sign, "1.5h", fn -> p.("1.5h") == :error end}
]

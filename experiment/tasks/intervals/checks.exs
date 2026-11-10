m = fn x -> apply(Intervals, :merge, [x]) end

raises = fn x ->
  try do
    m.(x)
    false
  rescue
    ArgumentError -> true
  end
end

[
  {:core, "the example", fn -> m.([{1, 3}, {2, 5}]) == [{1, 5}] end},
  {:core, "overlap given in the other order", fn -> m.([{2, 5}, {1, 3}]) == [{1, 5}] end},
  {:core, "an interval inside another", fn -> m.([{1, 10}, {2, 3}]) == [{1, 10}] end},
  {:core, "a chain of three", fn -> m.([{1, 4}, {3, 6}, {5, 9}]) == [{1, 9}] end},
  {:core, "duplicates", fn -> m.([{1, 2}, {1, 2}]) == [{1, 2}] end},
  {:core, "negative numbers", fn -> m.([{-5, -1}, {-2, 3}]) == [{-5, 3}] end},
  {:touching, "[{1, 2}, {2, 3}]", fn -> m.([{1, 2}, {2, 3}]) == [{1, 3}] end},
  {:adjacent, "[{1, 2}, {3, 4}]", fn -> m.([{1, 2}, {3, 4}]) == [{1, 2}, {3, 4}] end},
  {:order, "[{5, 6}, {1, 2}]", fn -> m.([{5, 6}, {1, 2}]) == [{1, 2}, {5, 6}] end},
  {:reversed, "{3, 1} raises ArgumentError", fn -> raises.([{3, 1}]) end},
  {:reversed, "{3, 1} among valid ones raises", fn -> raises.([{1, 2}, {3, 1}, {5, 6}]) end},
  {:empty, "[]", fn -> m.([]) == [] end},
  {:point, "[{2, 2}] stays", fn -> m.([{2, 2}]) == [{2, 2}] end},
  {:point, "{2, 2} inside {1, 3}", fn -> m.([{2, 2}, {1, 3}]) == [{1, 3}] end}
]

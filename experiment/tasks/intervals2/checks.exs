m = fn x -> apply(Intervals, :merge, [x]) end

[
  {:core, "the example", fn -> m.([{1, 3}, {2, 5}]) == [{1, 5}] end},
  {:core, "overlap given in the other order", fn -> m.([{2, 5}, {1, 3}]) == [{1, 5}] end},
  {:core, "an interval inside another", fn -> m.([{1, 10}, {2, 3}]) == [{1, 10}] end},
  {:core, "a chain of three", fn -> m.([{1, 4}, {3, 6}, {5, 9}]) == [{1, 9}] end},
  {:core, "duplicates", fn -> m.([{1, 2}, {1, 2}]) == [{1, 2}] end},
  {:core, "negative numbers", fn -> m.([{-5, -1}, {-2, 3}]) == [{-5, 3}] end},
  {:core, "far apart stays apart", fn -> m.([{1, 2}, {7, 9}]) == [{1, 2}, {7, 9}] end},
  {:touching, "[{1, 2}, {2, 3}]", fn -> m.([{1, 2}, {2, 3}]) == [{1, 3}] end},
  {:adjacent, "[{1, 2}, {3, 4}] merges", fn -> m.([{1, 2}, {3, 4}]) == [{1, 4}] end},
  {:adjacent, "[{1, 2}, {4, 5}] does not", fn -> m.([{1, 2}, {4, 5}]) == [{1, 2}, {4, 5}] end},
  {:order, "[{5, 6}, {1, 2}]", fn -> m.([{5, 6}, {1, 2}]) == [{1, 2}, {5, 6}] end},
  {:reversed, "{3, 1} is read as {1, 3}", fn -> m.([{3, 1}]) == [{1, 3}] end},
  {:reversed, "{9, 7} among others", fn -> m.([{1, 2}, {9, 7}]) == [{1, 2}, {7, 9}] end},
  {:empty, "[]", fn -> m.([]) == [] end},
  {:point, "[{2, 2}] gives []", fn -> m.([{2, 2}]) == [] end},
  {:point, "[{2, 2}, {5, 6}]", fn -> m.([{2, 2}, {5, 6}]) == [{5, 6}] end}
]

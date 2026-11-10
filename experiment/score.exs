# Scores one solution against a task's hidden checks.
#
#     elixir experiment/score.exs TASK path/to/solution.ex [more .ex files]
#
# Prints one line per check, then a summary: how many core checks pass and how
# many of the task's decisions the solution got right (a decision is right only
# if all of its checks pass). The checks are plain functions: no Mix, no deps.

{task, files} =
  case System.argv() do
    [task | [_ | _] = files] -> {task, files}
    _ ->
      IO.puts(:stderr, "usage: elixir score.exs TASK solution.ex [more.ex]")
      System.halt(2)
  end

dir = Path.join([__DIR__, "tasks", task])

unless File.dir?(dir) do
  IO.puts(:stderr, "no such task: #{task}")
  System.halt(2)
end

Code.compiler_options(ignore_module_conflict: true)

compiled? =
  try do
    Enum.each(files, &Code.require_file/1)
    true
  rescue
    e ->
      IO.puts("solution does not compile: #{Exception.message(e)}")
      false
  end

{checks, _} = Code.eval_file(Path.join(dir, "checks.exs"))

# Each check runs in its own process with a time limit, so a crash or an
# endless loop fails that check only.
run = fn fun ->
  task = Task.async(fn ->
    try do
      fun.() == true
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end)

  case Task.yield(task, 2_000) || Task.shutdown(task, :brutal_kill) do
    {:ok, result} -> result
    _ -> false
  end
end

results = for {id, desc, fun} <- checks, do: {id, desc, compiled? and run.(fun)}

for {id, desc, ok} <- results do
  IO.puts("#{if ok, do: "pass", else: "FAIL"}  #{String.pad_trailing(to_string(id), 14)} #{desc}")
end

{core, decisions} = Enum.split_with(results, fn {id, _, _} -> id == :core end)
core_ok = Enum.count(core, fn {_, _, ok} -> ok end)
by_decision = Enum.group_by(decisions, fn {id, _, _} -> id end, fn {_, _, ok} -> ok end)
right = Enum.count(by_decision, fn {_, oks} -> Enum.all?(oks) end)
wrong = for {id, oks} <- by_decision, not Enum.all?(oks), do: id

IO.puts("")
IO.puts("RESULT task=#{task} core=#{core_ok}/#{length(core)} decisions=#{right}/#{map_size(by_decision)}" <>
          if(wrong == [], do: "", else: " wrong=#{wrong |> Enum.sort() |> Enum.join(",")}"))

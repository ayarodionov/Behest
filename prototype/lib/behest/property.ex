defmodule Behest.Property do
  @moduledoc false

  @runs 100

  def run(module, gen_fun, check_fun, seed) do
    :rand.seed(:exsss, {seed, seed + 1, seed + 2})
    gens = apply(module, gen_fun, [])

    Enum.reduce_while(1..@runs, :ok, fn i, :ok ->
      size = div(i, 2) + 1
      binding = Map.new(gens, fn {var, gen} -> {var, gen.(size)} end)

      result =
        try do
          apply(module, check_fun, [binding])
        rescue
          e -> {:raised, e}
        end

      case result do
        true -> {:cont, :ok}
        {:raised, e} -> {:halt, {:counterexample, binding, "raised: " <> Exception.message(e)}}
        other -> {:halt, {:counterexample, binding, "returned: #{inspect(other)}"}}
      end
    end)
  end
end

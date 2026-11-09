defmodule Behest do
  @moduledoc """
  Prototype of Behest contracts as Elixir macros.

  A `defspec` puts the human-approved contract (examples, properties,
  effects) next to the implementation. The build fails when:

    * an example does not hold,
    * a property finds a counterexample,
    * the implementation uses an effect it did not declare.

      defmodule Stats do
        use Behest

        defspec median(xs) do
          examples do
            median([3.0, 1.0, 2.0]) == {:ok, 2.0}
            median([]) == {:error, :empty}
          end

          property "order does not matter", xs: list_of(float()) do
            median(xs) == median(Enum.shuffle(xs))
          end

          implementation do
            ...
          end
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Behest, only: [defspec: 2]
      Module.register_attribute(__MODULE__, :behest_specs, accumulate: true)
      Module.register_attribute(__MODULE__, :behest_examples, accumulate: true)
      Module.register_attribute(__MODULE__, :behest_properties, accumulate: true)
      @before_compile Behest
      @after_compile Behest
    end
  end

  @doc "Defines a function together with its contract."
  defmacro defspec(head, do: block) do
    {name, args} = Macro.decompose_call(head)
    arity = length(args)
    parts = parse_parts(block, name, arity)
    impl = parts.implementation || raise_compile(__CALLER__, "defspec #{name}/#{arity} has no implementation block")

    direct = Behest.Effects.scan(impl)
    local_calls = Behest.Effects.local_calls(impl)

    example_defs =
      parts.examples
      |> Enum.with_index(1)
      |> Enum.map(fn {{expr, line}, i} -> example_fun(name, arity, i, expr, line) end)

    property_defs =
      parts.properties
      |> Enum.with_index(1)
      |> Enum.map(fn {prop, i} -> property_funs(name, arity, i, prop) end)

    spec = %{
      name: name,
      arity: arity,
      line: __CALLER__.line,
      declared: parts.effects,
      direct: direct,
      local_calls: local_calls,
      examples: length(parts.examples),
      properties: Enum.map(parts.properties, & &1.title)
    }

    quote do
      @behest_specs unquote(Macro.escape(spec))
      def unquote(head), do: unquote(impl)
      unquote_splicing(example_defs)
      unquote_splicing(property_defs)
    end
  end

  # -- parsing the defspec body ---------------------------------------------

  defp parse_parts(block, name, arity) do
    statements =
      case block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    Enum.reduce(statements, %{examples: [], properties: [], effects: [], implementation: nil}, fn
      {:examples, _, [[do: body]]}, acc ->
        exprs =
          case body do
            {:__block__, _, list} -> list
            single -> [single]
          end

        %{acc | examples: acc.examples ++ Enum.map(exprs, &{&1, line_of(&1)})}

      {:property, meta, [title, gens, [do: body]]}, acc when is_binary(title) and is_list(gens) ->
        %{acc | properties: acc.properties ++ [%{title: title, gens: gens, body: body, line: meta[:line]}]}

      {:property, meta, [title, [{:do, _} | _] = _]}, _acc ->
        raise CompileError,
          line: meta[:line],
          description: "property #{inspect(title)} in #{name}/#{arity} needs generators, e.g. property \"...\", xs: list_of(integer()) do ... end"

      {:effects, _, [list]}, acc when is_list(list) ->
        %{acc | effects: acc.effects ++ list}

      {:implementation, _, [[do: body]]}, acc ->
        %{acc | implementation: body}

      other, _acc ->
        raise CompileError,
          line: line_of(other),
          description:
            "unexpected statement in defspec #{name}/#{arity}: #{Macro.to_string(other)}. " <>
              "Allowed: examples, property, effects, implementation"
    end)
  end

  defp line_of({_, meta, _}) when is_list(meta), do: meta[:line]
  defp line_of(_), do: nil

  defp raise_compile(env, msg), do: raise(CompileError, file: env.file, line: env.line, description: msg)

  # -- generated helper functions -------------------------------------------

  defp example_fun(name, arity, i, expr, line) do
    fun = :"__behest_example_#{name}_#{arity}_#{i}__"
    source = Macro.to_string(expr)

    body =
      case expr do
        {:==, _, [left, right]} ->
          quote do
            l = unquote(left)
            r = unquote(right)
            {l == r, l, r}
          end

        other ->
          quote do
            v = unquote(other)
            {v == true, v, true}
          end
      end

    quote do
      @doc false
      def unquote(fun)() do
        try do
          {:result, unquote(body)}
        rescue
          e -> {:raised, e}
        end
      end

      @behest_examples {unquote(fun), unquote(source), unquote(line), unquote(name), unquote(arity)}
    end
  end

  defp property_funs(name, arity, i, %{title: title, gens: gens, body: body, line: line}) do
    gen_fun = :"__behest_pgen_#{name}_#{arity}_#{i}__"
    check_fun = :"__behest_pcheck_#{name}_#{arity}_#{i}__"

    gen_list =
      Enum.map(gens, fn {var, gen_expr} -> {var, gen_expr} end)

    bindings =
      Enum.map(gens, fn {var, _} ->
        quote do
          unquote(Macro.var(var, nil)) = Map.fetch!(binding, unquote(var))
        end
      end)

    quote do
      @doc false
      def unquote(gen_fun)() do
        import Behest.Gen
        unquote(gen_list)
      end

      @doc false
      def unquote(check_fun)(binding) do
        unquote_splicing(bindings)
        unquote(body)
      end

      @behest_properties {unquote(gen_fun), unquote(check_fun), unquote(title), unquote(line), unquote(name),
                          unquote(arity)}
    end
  end

  # -- compile hooks --------------------------------------------------------

  @doc false
  defmacro __before_compile__(env) do
    specs = env.module |> Module.get_attribute(:behest_specs) |> Enum.reverse()
    examples = env.module |> Module.get_attribute(:behest_examples) |> Enum.reverse()
    properties = env.module |> Module.get_attribute(:behest_properties) |> Enum.reverse()
    Behest.Effects.check!(specs, env)

    quote do
      @doc false
      def __behest__(:specs), do: unquote(Macro.escape(specs))
      def __behest__(:examples), do: unquote(Macro.escape(examples))
      def __behest__(:properties), do: unquote(Macro.escape(properties))
    end
  end

  @doc false
  def __after_compile__(env, _bytecode) do
    module = env.module
    seed = seed()

    for {fun, source, line, name, arity} <- module.__behest__(:examples) do
      case apply(module, fun, []) do
        {:result, {true, _, _}} ->
          :ok

        {:result, {false, got, expected}} ->
          raise CompileError,
            file: env.file,
            line: line,
            description:
              "example failed for #{name}/#{arity}:\n    #{source}\n  got:      #{inspect(got)}\n  expected: #{inspect(expected)}"

        {:raised, e} ->
          raise CompileError,
            file: env.file,
            line: line,
            description: "example raised for #{name}/#{arity}:\n    #{source}\n  #{Exception.message(e)}"
      end
    end

    for {gen_fun, check_fun, title, line, name, arity} <- module.__behest__(:properties) do
      case Behest.Property.run(module, gen_fun, check_fun, seed) do
        :ok ->
          :ok

        {:counterexample, binding, reason} ->
          raise CompileError,
            file: env.file,
            line: line,
            description:
              "property #{inspect(title)} failed for #{name}/#{arity}\n  counterexample: #{inspect(binding)}\n  #{reason}\n  reproduce with BEHEST_SEED=#{seed}"
      end
    end

    :ok
  end

  defp seed do
    case System.get_env("BEHEST_SEED") do
      nil -> :erlang.phash2(:erlang.unique_integer())
      s -> String.to_integer(s)
    end
  end
end

defmodule BehestTest do
  use ExUnit.Case, async: false

  alias Behest.Examples.{RateLimit, Stats}

  test "example modules compile and work" do
    assert Stats.median([5, 1, 3]) == {:ok, 3}
    assert {:ok, _} = RateLimit.check_now(%{}, :a, 3, 1000)
  end

  test "a wrong example fails the build" do
    assert_raise CompileError, ~r/example failed for double\/1/, fn ->
      Code.compile_string("""
      defmodule BadExample do
        use Behest
        defspec double(x) do
          examples do
            double(2) == 5
          end
          implementation do
            x * 2
          end
        end
      end
      """)
    end
  end

  test "a false property fails the build with a counterexample" do
    assert_raise CompileError, ~r/property "always positive" failed.*counterexample/s, fn ->
      Code.compile_string("""
      defmodule BadProperty do
        use Behest
        defspec negate(x) do
          property "always positive", x: integer() do
            negate(x) > 0
          end
          implementation do
            -x
          end
        end
      end
      """)
    end
  end

  test "an undeclared effect fails the build" do
    assert_raise CompileError, ~r/:time \(from System.system_time\)/, fn ->
      Code.compile_string("""
      defmodule BadEffect do
        use Behest
        defspec stamp(x) do
          implementation do
            {x, System.system_time()}
          end
        end
      end
      """)
    end
  end

  test "effects are inherited from called specs" do
    assert_raise CompileError, ~r/:ets \(from put\/1\)/, fn ->
      Code.compile_string("""
      defmodule BadInherited do
        use Behest
        defspec put(x) do
          effects [:ets]
          implementation do
            :ets.insert(:t, {x})
          end
        end
        defspec put_twice(x) do
          implementation do
            put(x)
            put(x)
          end
        end
      end
      """)
    end
  end

  test "a declared effect compiles" do
    assert [{_, _}] =
             Code.compile_string("""
             defmodule GoodEffect do
               use Behest
               defspec say(x) do
                 effects [:io]
                 implementation do
                   IO.inspect(x)
                 end
               end
             end
             """)
  end
end

defmodule BehestTest do
  use ExUnit.Case, async: false

  alias Behest.Examples.{Gcd, RateLimit, Stats}

  test "example modules compile and work" do
    assert Stats.median([5, 1, 3]) == {:ok, 3}
    assert {:ok, _} = RateLimit.check_now(%{}, :a, 3, 1000)
    assert Gcd.gcd(48, 36) == 12
  end

  test "a plausible but wrong gcd is caught by the contract" do
    # returns the smaller number: right for gcd(6, 12), wrong in general
    assert_raise CompileError, ~r/example failed for gcd\/2/, fn ->
      Code.compile_string("""
      defmodule WrongGcd do
        use Behest
        defspec gcd(a, b) do
          examples do
            gcd(6, 12) == 6
            gcd(12, 18) == 6
          end
          implementation do
            min(abs(a), abs(b))
          end
        end
      end
      """)
    end
  end

  test "properties alone catch a wrong gcd when the examples miss it" do
    assert_raise CompileError, ~r/property "divides both numbers" failed.*counterexample/s, fn ->
      Code.compile_string("""
      defmodule WrongGcd2 do
        use Behest
        defspec gcd(a, b) do
          examples do
            gcd(6, 12) == 6
          end
          property "divides both numbers", a: positive_integer(), b: positive_integer() do
            g = gcd(a, b)
            rem(a, g) == 0 and rem(b, g) == 0
          end
          implementation do
            min(a, b)
          end
        end
      end
      """)
    end
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

  test "an open item fails the build and lists the question" do
    error =
      assert_raise CompileError, fn ->
        Code.compile_string("""
        defmodule WithOpen do
          use Behest
          defspec median(xs) do
            open "NaN handling: skip, error, or propagate?"
            examples do
              median([1, 2, 3]) == 2
            end
            implementation do
              Enum.at(Enum.sort(xs), div(length(xs), 2))
            end
          end
          defspec mean(xs) do
            open "empty list: error or 0?"
            implementation do
              Enum.sum(xs) / length(xs)
            end
          end
        end
        """)
      end

    message = Exception.message(error)
    assert message =~ "unresolved open items"
    assert message =~ "median/1"
    assert message =~ "NaN handling: skip, error, or propagate?"
    assert message =~ "mean/1"
    assert message =~ "empty list: error or 0?"
  end

  test "removing the open item lets the build pass" do
    assert [{_, _}] =
             Code.compile_string("""
             defmodule Answered do
               use Behest
               defspec median(xs) do
                 examples do
                   median([1, 2, 3]) == 2
                   median([1.0, :nan]) == :nan_not_supported
                 end
                 implementation do
                   if Enum.any?(xs, &(&1 == :nan)), do: :nan_not_supported, else: Enum.at(Enum.sort(xs), div(length(xs), 2))
                 end
               end
             end
             """)
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

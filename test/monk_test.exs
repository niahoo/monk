defmodule MonkTest do
  use ExUnit.Case
  use Monk

  test "ok/err wrappers wrap values" do
    assert ok("hello") === {:ok, "hello"}
    assert err("hello") === {:error, "hello"}
  end

  test "ok() does not wrap :ok" do
    assert ok(:ok) === :ok
    assert ok(ok(:ok)) === :ok
  end

  test "ok/err wrappers do not rewrap" do
    assert ok(ok("hello")) === ok("hello")
    assert err(err("hello")) === err("hello")
  end

  test "no pipes" do
    assert {:ok, 1} === monk 1
    assert {:error, nil} === monk nil
  end

  test "generic wrapper wraps nil and :error as errors, other values as ok" do
    assert wrap(nil) === err(nil)
    assert wrap(:error) === err(nil)
    assert wrap({:error, "you suck !"}) === {:error, "you suck !"}
    assert wrap(1) === ok(1)
    assert wrap({:ok, 1}) === {:ok, 1}
    assert wrap(:ok) === :ok
  end

  test "generic unwrapper" do
    assert unwrap({:ok,1}) === unwrap({:ok,{:ok,{:ok,{:ok,{:ok,1}}}}})
    assert unwrap({:ok, 1}) === 1
    assert unwrap({:error, "fail"}) ===
      unwrap({:error,{:error,{:error,{:error,{:error,"fail"}}}}})
    assert unwrap({:error, "fail"}) === "fail"
  end

  test "syntax" do
    # we want to support (monk pipes) and (do/end) expressions
    expected = {:ok, 4}

    # with parens
    assert monk(1 |> double |> power 2, :any) === expected

    # without …
    without_parens = monk 1 |> double |> power 2
    assert without_parens === expected

    # without parens and another argument in the end (must be captured)
    trailing = monk 1 |> double |> power 2, :trailing_coma_arg
    assert trailing === expected

    # do end syntax
    assert expected === (monk do
      1 |> double |> power 2
    end)
    assert expected === (monk do: 1 |> double |> power 2)
  end

  test "autowrap" do
    assert {:ok, 2} === monk 1 |> increment_nowrap
  end

  test "failures" do
    assert {:error, "always fail"} ===
      monk 1
      |> increment_nowrap
      |> fails
      |> Any.thing

    assert {:error, nil} === monk 1 |> increment_nowrap |> get_nil |> Any.thing

    assert {:error, "always fail"} ===
      monk 1
      |> increment_nowrap
      |> fails
      |> wins

    assert {:ok, "always wins"} === monk 1
      |> increment_nowrap
      |> ok(fails) # wrapping in ok cancels the failure
      |> wins
  end

  test "no parens do syntax" do
    monk do
      true |> assert("true is not true")
    end
  end

  test "pass along single :ok atom" do
    result = monk :ok |> accept_ok
    assert result === {:ok, :success}

    result = monk "something" |> wrap_any
    assert result === {:ok, {:wrap, "something"}}

    result = monk "something" |> identity
    assert result === {:ok, "something"}

    result = monk "something" |> provide_ok
    assert result === :ok

    result = monk "something" |> ok(provide_ok)
    assert result === :ok
  end

  ## tests helpers

  defp double(x), do: {:ok, x * 2}
  defp power(x, exp, _ \\ :osef), do: {:ok, pow(x, exp)}

  defp increment_nowrap(x), do: x + 1

  defp fails(_), do: {:error, "always fail"}
  defp get_nil(_), do: nil
  defp wins(_) do
    {:ok, "always wins"}
  end

  defp pow(_, 0), do: 1
  defp pow(a, 1), do: a
  defp pow(a, n) when rem(n, 2) === 0 do
    tmp = pow(a, div(n, 2))
    tmp * tmp
  end
  defp pow(a, n) do
    a * pow(a, n-1)
  end

  defp provide_ok(_), do: :ok

  defp identity(x), do: x

  defp wrap_any(x), do: {:wrap, x}

  defp accept_ok(:ok), do: {:ok, :success}
  defp accept_ok(x), do: {:error, {:not_ok, x}}

end

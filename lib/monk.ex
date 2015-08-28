defmodule Monk do
  @moduledoc """
  Monk is your everyday ok/error monad.

  The monk macro allows you to pipe functions that accept a bare value, and
  returns values in `{ok:, val}` or `{:error, val}`.

  If a function returns `{:error, reason}`, the subsequent functions in the pipe
  will *not* be called and the result of the whole expression will be the
  `{:error, _}` tuple

  Of course, you need to `use Monk` to be able to call the macro.

  Two syntaxes are supported :

      result = monk data |> map |> reduce

      monk do
        some |> nice |> piping
      end

  If you except an error from a function, you can catch the error and continue
  through the pipe with the ok/1 function. The next function will receive the
  `{:error, reason}` tuple as it's first argument. Here, `report_error` receives
  any value that is returned by `do_things`

      monk bad_data |> ok(do_things) |> report_error

  This could be read as the following :

      {:ok, d} = bad_data()
      {:ok, {:error, e}} = ok(do_things(d))
      report_error({:error, e})
  """

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  ## -- public API -----------------------------------------------------------

  def ok({:ok, _} = wrapped), do: wrapped
  def ok(:ok), do: :ok
  def ok(val), do: {:ok, val}

  def err({:error, _} = wrapped), do: wrapped
  def err(reason), do: {:error, reason}

  def wrap(nil),    do: err(nil)
  def wrap(:error), do: err(nil)
  def wrap({:error, _} = wrapped), do: wrapped
  def wrap({:ok, _} = wrapped), do: wrapped
  def wrap(val),  do: ok(val)

  def unwrap({:ok, val}), do: unwrap_ok(val)
  def unwrap({:error, reason}), do: unwrap_err(reason)
  def unwrap(val), do: val

  def unwrap_ok({:ok, val}), do: unwrap_ok(val)
  def unwrap_ok(val), do: val

  def unwrap_err({:error, reason}), do: unwrap_err(reason)
  def unwrap_err(reason), do: reason

  ## -- macro stuff ----------------------------------------------------------

  defmacro monk(do: pipes) do
    first_pipe_call(pipes)
  end

  defmacro monk(pipes) do
    quoted = first_pipe_call(pipes)
    quoted
  end

  defp first_pipe_call(pipes) do
    [{firstcall, _}|calls] = Macro.unpipe pipes
    write_case(firstcall, calls)
  end

{:ok, [line: 69], [{:fails, [line: 69], nil}]}


  # in cas the current call in the pipe is ok(something), we do not pipe into
  # the ok function, but we force the value to be ok(something(val))
  defp pipe_call([{call={:ok, meta, [sub_call]}, 0}|calls], val) do
    force_ok = quote do
      ok(unquote(Macro.pipe(quote(do: unwrap(unquote(val))), sub_call, 0)))
    end
    write_case(force_ok, calls)
  end

  defp pipe_call([{call, pos}|calls], val) do
    piped = Macro.pipe(quote(do: unwrap(unquote(val))), call, pos)
    write_case(piped, calls)
  end

  defp pipe_call([], val) do
    quote do: wrap(unquote(val))
  end

  defp write_case(piped, calls) do
    quote do
      case wrap(unquote(piped)) do
        {:ok, val} -> unquote(pipe_call(calls, quote do: val))
        {:error, _} = e -> e
      end
    end
  end

end

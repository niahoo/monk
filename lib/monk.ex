defmodule Monk do
  @moduledoc """
  Monk is your everyday `:ok | :error` monad.

  The monk macro allows you to pipe functions that accept a mere value, and
  returns wrapped values like `{ok:, val}` or `{:error, val}`.

  If a function returns `{:error, reason}`, the subsequent functions in the pipe
  will *not* be called and the result of the whole expression will be the
  `{:error, _}` tuple.

  Some functions don't return any data, just `:ok`. The value `:ok` (the single
  atom) will be passed along as-is to the next function in the pipe.




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

  @doc """
  Wraps a value in a {:ok, _} tuple. Values already wrapped are not touched.
  """
  @spec ok(term) :: {:ok, term}
  def ok({:ok, _} = val), do: val
  def ok(:ok), do: :ok
  def ok(val), do: {:ok, val}

  @doc """
  Wraps an error description in a {:error, _} tuple. Values already wrapped are
  not touched.
  """
  @spec err(term) :: {:error, term}
  def err({:error, _} = reason), do: reason
  def err(reason), do: {:error, reason}

  @doc """
  Wraps a term in a {:ok, _} tuple or in an error if the value is either nil or
  the :error atom. Values already wrapped are not touched.
  """
  @spec wrap(term) :: {:error, term} | {:ok, term}
  def wrap(nil),    do: err(nil)
  def wrap(:error), do: err(nil)
  def wrap({:error, _} = val), do: val
  def wrap({:ok, _} = val), do: val
  def wrap(val),  do: ok(val)



  @doc """
  Unwraps all levels of {:ok, _} or {:error, _} wrappings.

  The top wrap defines what is unwrapped. If the top wrap is :ok, the :error
  wraps will not be removed :

      unwrap({:ok,{:ok,{:error,val}}}) -> {:error,val}

  """
  def unwrap({:ok, val}), do: unwrap_ok(val)
  def unwrap({:error, reason}), do: unwrap_err(reason)
  def unwrap(val), do: val

  defp unwrap_ok({:ok, val}), do: unwrap_ok(val)
  defp unwrap_ok(val), do: val

  defp unwrap_err({:error, reason}), do: unwrap_err(reason)
  defp unwrap_err(reason), do: reason

  ## -- macro stuff ----------------------------------------------------------

  defmacro monk(do: pipe_expr) do
    first_pipe_call(pipe_expr)
  end

  defmacro monk(pipe_expr) do
    quoted = first_pipe_call(pipe_expr)
    # IO.puts Macro.to_string quoted
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
        :ok -> unquote(pipe_call(calls, :ok))
        {:ok, val} -> unquote(pipe_call(calls, quote do: val))
        {:error, _} = e -> e
      end
    end
  end

end

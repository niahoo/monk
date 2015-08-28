# Monk

This is copied from the moduledocs. Better documentation to come.

Monk is your everyday `:ok | :error` monad.

### Basic usage

The monk macro allows you to pipe functions that accept a mere value, and
returns wrapped values like `{ok:, val}` or `{:error, val}`.

If a function returns `{:error, reason}`, the subsequent functions in the pipe
will *not* be called and the result of the whole expression will be the
`{:error, _}` tuple

Of course, you need to `use Monk` to be able to call the macro.

Two syntaxes are supported :

    result = monk data |> map |> reduce

    monk do
      some |> nice |> piping
    end

### Capturing errors

If you except an error from a function, you can catch the error and continue
through the pipe with the ok/1 function. The next function will receive the
`{:error, reason}` tuple as it's first argument. Here, `report_error` receives
any value that is returned by `do_things`

    monk bad_data |> ok(do_things) |> report_error

This could be read as the following :

    {:ok, d} = bad_data()
    {:ok, {:error, e}} = ok(do_things(d))
    report_error({:error, e})

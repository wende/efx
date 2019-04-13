defmodule Efx do
  defstruct captured_effects: %{}, continuations: %{}

  def register_effect(mod, fun, arity) do
    start()
    :ets.insert(__MODULE__, {mod, fun, arity})
  end

  def start() do
    case :ets.info(__MODULE__) do
      :undefined ->
        :ets.new(__MODULE__, [:named_table])
        :ok

      _ ->
        :ok
    end
  end

  @effects %{
    {File, :read, 1} => [STD.WRITE]
  }

  def replace_effects(ast) do
    Macro.prewalk(ast, fn
      ast = {{:., _, [_module, _function]}, _, _args} ->
        replace_call(ast)

      ast ->
        ast
    end)
  end

  def replace_call(ast = {{:., _, [mod_ast, fun]}, _, args}) do
    mod = replace_module(mod_ast)

    case Map.get(@effects, {mod, fun, length(args)}) |> IO.inspect() do
      nil ->
        ast

      [_ | _] ->
        quote do
          Efx.eff(unquote(mod), unquote(fun), unquote(args))
        end
    end
  end

  def replace_call(ast) do
    ast
  end

  def replace_module({:__aliases__, _, path}) do
    Module.concat(path)
  end

  def eff(mod, fun, args) do
    IO.puts("Calling #{mod} #{fun} #{inspect(args)} at #{__MODULE__}")

    efx = Process.get(__MODULE__, %Efx{})

    efx
    |> Map.get(:captured_effects)
    |> Map.get({mod, fun, length(args)})
    |> case do
      nil ->
        IO.puts("Not found")
        apply(mod, fun, args)

      [{ref, handler} | rest] ->
        IO.inspect({ref, handler})
        Process.put(__MODULE__, put_in(efx.captured_effects[{mod, fun, args}], rest))

        handler.(args, fn result ->
          efx = Process.get(__MODULE__, %Efx{})
          new_efx = put_in(efx.continuations[ref], result)
          Process.put(__MODULE__, new_efx)
        end)
    end
  end

  defmacro handle(do: code, catch: cases) do
    handlers =
      for {:->, _, [[left, k], body]} <- cases do
        {mod, fun, args} = tuplify_call(left, __CALLER__)

        quote do
          ref = Kernel.make_ref()

          h = fn [unquote_splicing(args)], unquote(k) ->
            unquote(body)

            case Process.get(unquote(__MODULE__), %Efx{}).continuations[ref] do
              nil -> throw(:efx_no_cont)
              result -> result
            end
          end

          efx = Process.get(unquote(__MODULE__), %Efx{})

          new_efx =
            put_in(
              efx.captured_effects[{unquote(mod), unquote(fun), unquote(length(args))}],
              [{ref, h}]
            )

          IO.puts("Putting #{inspect(new_efx)} to #{unquote(__MODULE__)}")
          Process.put(unquote(__MODULE__), new_efx)
        end
      end

    quote do
      unquote(handlers)
      unquote(code)
    end
  end

  defp tuplify_call({{:., _, [mod, fun]}, _, args}, caller) do
    {Macro.expand(mod, caller), fun, args}
  end

  defp tuplify_call({:{}, _, [mod, fun, args]}, _) do
    {mod, fun, args}
  end
end

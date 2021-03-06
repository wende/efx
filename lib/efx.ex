defmodule Efx do
  defstruct handlers: %{}, continuations: %{}

  defmacro __using__(_) do
    quote do
      import Efx, only: [eff: 1]
    end
  end

  defmacro defwitheff({name, _, args} = definition, body) when is_list(args) do
    IO.puts("Defining #{inspect(definition)}")
    mod = __CALLER__.module

    :ok = Efx.Definition.Server.define_ast(mod, name, length(args), body)

    quote do
      def(unquote(definition), unquote(body))
    end
  end

  defmacro defwitheff({name, _, context} = definition, body) when is_atom(context) do
    IO.puts("Defining #{inspect(definition)}")
    mod = __CALLER__.module

    :ok = Efx.Definition.Server.define_ast(mod, name, 0, body)

    quote do
      def(unquote(definition), unquote(body))
    end
  end

  defmacro eff({:::, _, [left, right]}) do
    {name, arity, args} = function_and_args_ast(left)

    effects =
      effects_ast(right, __CALLER__)
      |> resolve_free_vars(args)

    Efx.Definition.Server.infer(__CALLER__.module, name, arity)
    Efx.Definition.Server.define_effects(__CALLER__.module, name, arity, effects)
  end

  @manifest_file Path.join(Mix.Project.manifest_path(), "effect_definitions.blob")

  @spec read_manifest() :: {:error, atom()} | {:ok, list({atom, atom, integer})}
  def read_manifest() do
    @manifest_file
    |> File.read()
    |> case do
      {:ok, content} -> {:ok, :erlang.binary_to_term(content)}
      err -> err
    end
  end

  @spec write_manifest(list({atom, atom, integer})) :: :ok | {:error, atom()}
  def write_manifest(effects) do
    @manifest_file |> File.write(:erlang.term_to_binary(effects))
  end

  def clean_manifest() do
    @manifest_file |> File.rm()
  end

  @base_effects_file "./.efx.exs"
  def read_base_effects() do
    case File.read(@base_effects_file) do
      {:ok, content} ->
        {effects, _} = Code.eval_string(content)
        effects

      {:error, _} ->
        []
    end
  end

  def gather_effects(_ast) do
    []
  end

  def replace_effects(ast, effects) do
    Macro.postwalk(ast, fn
      ast = {{:., _, [_module, _function]}, _, _args} ->
        replace_call(ast, effects)

      {:def, m, definition} ->
        quote do
          import Efx
          unquote({:defwitheff, m, definition})
        end

      ast ->
        ast
    end)
  end

  @spec replace_call(any(), effects :: list({atom, atom, integer})) :: any()
  def replace_call(ast = {{:., _, [mod_ast, fun]}, _, args}, effects) do
    mod = replace_module(mod_ast)

    if Enum.member?(effects, {mod, fun, length(args)}) do
      IO.inspect("Replacing call to eff #{inspect({mod, fun, args})}")

      quote do
        Efx.call_effect(unquote(mod), unquote(fun), unquote(args))
      end
    else
      ast
    end
  end

  def replace_call(ast, _effects) do
    ast
  end

  @spec replace_module({:__aliases__, any(), [atom() | binary()]}) :: atom()
  def replace_module({:__aliases__, _, path}) do
    Module.concat(path)
  end

  def replace_module(atom_module) when is_atom(atom_module), do: atom_module
  # When module is a variable
  def replace_module(var = {_, _, _}), do: var

  @spec call_effect(any(), any(), [any()]) :: any()
  def call_effect(mod, fun, args) do
    IO.puts("Calling #{mod} #{fun} #{inspect(args)} on #{inspect(self())}")

    efx = Efx.get()

    efx
    |> Map.get(:handlers)
    |> Map.get({mod, fun, length(args)})
    |> case do
      nil ->
        apply(mod, fun, args)

      handlers ->
        handlers
        |> Enum.reverse()
        |> Enum.reduce_while(:no_match, fn handler, _ ->
          case handler.(args) do
            {:ok, body} -> {:halt, body}
            {:error, :no_match} -> {:cont, :no_match}
          end
        end)
        |> case do
          :no_match -> throw(:no_match)
          body -> body
        end
    end
  end

  defmacro handle(do: code, catch: cases) do
    handlers =
      for {:->, _, [[left], body]} <- cases do
        {mod, fun, args} = tuplify_call(left, __CALLER__)

        quote do
          fn
            [unquote_splicing(args)] -> {:ok, unquote(body)}
            _ -> {:error, :no_match}
          end
          |> Efx.put_handler({unquote(mod), unquote(fun), unquote(length(args))})
        end
      end

    quote do
      unquote(handlers)
      unquote(code)
    end
  end

  def put_handler(handler, modfunarity) do
    Efx.get()
    |> update_in(
      [Access.key(:handlers), modfunarity],
      fn
        nil -> [handler]
        handlers -> [handler | handlers]
      end
    )
    |> Efx.put()
  end

  def put_continuation(ref, result) do
    efx = Process.get(Efx, %Efx{})
    new_efx = put_in(efx.continuations[ref], result)
    Process.put(Efx, new_efx)
  end

  def get_continuation(ref) do
    Efx.get().continuations[ref]
  end

  def get() do
    Process.get(unquote(Efx), %Efx{})
  end

  def put(efx) do
    Process.put(unquote(Efx), efx)
  end

  defp tuplify_call({{:., _, [mod, fun]}, _, args}, caller) do
    {Macro.expand(mod, caller), fun, args}
  end

  defp tuplify_call({:{}, _, [mod, fun, args]}, _) do
    {mod, fun, args}
  end

  defp function_and_args_ast({name, _, args}) do
    {name, length(args), args}
  end

  # Two effects
  def effects_ast({effect1, effect2}, env) do
    [eff_ast(effect1, env), eff_ast(effect2, env)] |> Efx.EffectSet.new()
  end

  # 1, 3 or more effects
  def effects_ast({:{}, _, args}, env) do
    Enum.map(args, &eff_ast(&1, env)) |> Efx.EffectSet.new()
  end

  def effects_ast(ast, _env) do
    throw("Incorrect effects definition: #{Macro.to_string(ast)}")
  end

  @spec eff_ast({:&, any(), [{:/, any(), [...]}, ...]}, any()) :: {any(), any(), any()}
  def eff_ast({:&, _, [{:/, _, [{{:., _, [mod, fun]}, _, []}, arity]}]}, env) do
    {Macro.expand(mod, env), fun, arity}
  end

  defp resolve_free_vars(effects, _vars) do
    # TODO Resolve free vars
    effects
  end
end

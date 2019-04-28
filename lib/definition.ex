defmodule Efx.Definition do
  alias Efx.EffectSet

  defmodule Module do
    @type t :: %Module{
            functions: %{
              optional({name :: atom(), arity :: tuple()}) =>
                {:resolved, Set.t()} | {:unresolved, term()}
            }
          }
    defstruct functions: %{}
  end

  @type t :: %{modules: %{optional(atom) => Module.t()}}
  defstruct modules: %{}

  def new() do
    %Efx.Definition{}
  end

  def prepare_ast(ast) do
    Macro.prewalk(ast, &Macro.expand(&1, __ENV__))
  end

  @spec get_effects(t(), atom(), atom(), integer()) :: EffectSet.t()
  def get_effects(definition, mod, fun, arity) do
    case get(definition, mod, fun, arity) do
      nil -> nil
      {:resolved, eff} -> eff
      {:unresolved, _} -> nil
    end
  end

  def get(definition, mod, fun, arity) do
    case Map.get(definition.modules, mod) do
      nil ->
        nil

      mod ->
        mod[{fun, arity}]
    end
  end

  @spec set_effects(t(), atom, atom(), integer(), EffectSet.t()) ::
          {:error, <<_::32, _::_*8>>}
          | {:ok, %{mod: %{optional({any(), any(), any()}) => any()}}}
  def set_effects(definition, mod, fun, arity, effects),
    do: set(definition, mod, fun, arity, {:resolved, effects})

  def set_ast(definition, mod, fun, arity, ast),
    do: set(definition, mod, fun, arity, {:unresolved, ast})

  defp set(definition, mod, fun, arity, effects) do
    case Map.get(definition.modules, mod) do
      nil ->
        {:ok,
         %{
           definition
           | modules: Map.put(definition.modules, mod, %{{fun, arity} => effects})
         }}

      other ->
        case other[{fun, arity}] do
          nil ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], effects)}

          {:unresolved, _ast} ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], effects)}

          {:resolved, already_defined} ->
            if EffectSet.equal?(already_defined, elem(effects, 1)) do
              {:ok, definition}
            else
              {:error, conflict({mod, fun, arity}, already_defined, effects)}
            end
        end
    end
  end

  defp conflict({mod, fun, arity}, original, {:resolved, annotation}) do
    # TODO do the conflic
    "Effects for #{mod}.#{fun}/#{arity} are already set to #{inspect(original)}. And #{
      inspect(annotation)
    } differs from prior definition"
  end

  defmacro eff({:::, _, [left, right]}) do
    {name, arity, args} = function_and_args_ast(left)

    effects =
      effects_ast(right, __CALLER__)
      |> resolve_free_vars(args)

    Efx.Definition.Server.define_effects(__CALLER__.module, name, arity, effects)
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

  defp resolve_free_vars(effects, vars) do
    # TODO
  end
end

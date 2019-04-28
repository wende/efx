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

  @type t :: %Efx.Definition{modules: %{optional(atom) => Module.t()}}
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
      nil -> EffectSet.new()
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

  defp set(definition, mod, fun, arity, value) do
    case Map.get(definition.modules, mod) do
      nil ->
        {:ok,
         %{
           definition
           | modules: Map.put(definition.modules, mod, %{{fun, arity} => value})
         }}

      other ->
        case {other[{fun, arity}], value} do
          {nil, {:resolved, effects}} when is_map(effects) ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], value)}

          {nil, {:unresolved, ast}} ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], {:unresolved, [ast]})}

          {{:unresolved, _ast}, {:resolved, _}} ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], value)}

          {{:unresolved, ast}, {:unresolved, new_ast}} ->
            {:ok, put_in(definition.modules[mod][{fun, arity}], {:unresolved, [new_ast | ast]})}

          {{:resolved, already_defined}, _} ->
            if EffectSet.equal?(already_defined, elem(value, 1)) do
              {:ok, definition}
            else
              {:error, conflict({mod, fun, arity}, already_defined, value)}
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
end

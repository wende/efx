defmodule Efx.EffectSet do
  @type t :: Set.t(effect())

  @type effect :: {module, fun, arity}

  def new(effects) do
    MapSet.new(effects)
  end

  def add_effect(effects, mod, fun, arity) do
    MapSet.put(effects, {mod, fun, arity})
  end

  def remove_effect(effects, mod, fun, arity) do
    MapSet.delete(effects, {mod, fun, arity})
  end

  def equal?(left, right), do: MapSet.equal?(left, right)
end

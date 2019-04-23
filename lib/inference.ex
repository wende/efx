defmodule Efx.Inference do
  alias Efx.Definition
  alias Efx.EffectSet

  @spec infer(Definition.t(), EffectSet.effect()) :: EffectSet.t()
  def infer(ast, effect) do
  end

  def cure(left, effect) do
  end
end

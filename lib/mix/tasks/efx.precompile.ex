defmodule Mix.Tasks.Efx.Precompile do
  use Mix.Task

  def run(_args) do
    project = Mix.Project.config()
    deps_path = project[:deps_path]

    Efx.clean_manifest()

    deps_path
    |> Path.join("**/**/*.ex")
    |> Path.wildcard()
    |> List.flatten()
    |> Enum.uniq()
    |> process_files()
  end

  def clean() do
    IO.puts("CLEANING")
  end

  @spec process_files(any()) :: :ok
  def process_files(files) do
    effects =
      files
      |> Enum.map(&Efx.gather_effects/1)
      |> List.flatten()
      |> Kernel.++(Efx.read_base_effects())
      |> IO.inspect(label: "Effects")

    :ok = Enum.each(files, &replace_effects(&1, effects))
  end

  def process_files_parralel(files) do
    effects =
      files
      |> Enum.map(fn file -> Task.async(fn -> Efx.gather_effects(file) end) end)
      |> Enum.map(&Task.await/1)
      |> Kernel.++(Efx.read_base_effects())

    :ok =
      files
      |> Enum.map(fn file -> Task.async(fn -> replace_effects(file, effects) end) end)
      |> Enum.each(&Task.await/1)
  end

  def replace_effects(file, effects) do
    old_code = File.read!(file)

    old_ast =
      old_code
      |> Code.string_to_quoted()

    ast =
      old_ast
      |> case do
        {:ok, ast} -> Efx.replace_effects(ast, effects)
        err -> err
      end

    if old_ast != ast do
      File.rm!(file)
      File.write!(file, Macro.to_string(ast))
    else
      :ok
    end
  end
end

defmodule Mix.Tasks.Compile.Efx do
  use Mix.Task

  def run(args) do
    # Nasty trick to crash on errors
    case Mix.Tasks.Compile.Elixir.run(args) do
      {:ok, _} ->
        project = Mix.Project.config()

        ex_paths = project[:elixirc_paths]
        deps_path = project[:deps_path]

        unless is_list(ex_paths) do
          Mix.raise(":elixirc_paths should be a list of paths, got: #{inspect(ex_paths)}")
        end

        Efx.clean_manifest()

        for path <- [deps_path | ex_paths] do
          path
          |> Path.join("**/**/*.ex")
          |> Path.wildcard()
        end
        |> List.flatten()
        |> process_files()

        :ok

      err ->
        err
    end
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
      File.write!(file <> ".efxtmp", old_code)
    else
      :ok
    end
  end
end

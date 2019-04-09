defmodule Mix.Tasks.Compile.Efx do
  use Mix.Task

  def run(_args) do
    project = Mix.Project.config()

    ex_paths = project[:elixirc_paths]
    deps_path = project[:deps_path]

    unless is_list(ex_paths) do
      Mix.raise(":elixirc_paths should be a list of paths, got: #{inspect(ex_paths)}")
    end

    for path <- [deps_path | ex_paths] do
      path
      |> Path.join("**/**/*.ex")
      |> Path.wildcard()
    end
    |> List.flatten()
    |> process_files()

    :ok
  end

  def process_files(files) do
    Enum.map(files, &each_file/1)
  end

  def process_files_parralel(files) do
    files
    |> Enum.map(fn file -> Task.async(fn -> each_file(file) end) end)
    |> Enum.map(&Task.await/1)
  end

  def each_file(file) do
    old_code = File.read!(file)

    old_ast =
      old_code
      |> Code.string_to_quoted()

    ast =
      old_ast
      |> case do
        {:ok, ast} -> Efx.replace_effects(ast)
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

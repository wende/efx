defmodule Mix.Tasks.Compile.PostEfx do
  use Mix.Task

  def run(_) do
    project = Mix.Project.config()

    ex_paths = project[:elixirc_paths]
    deps_path = project[:deps_path]

    for path <- [deps_path | ex_paths] do
      path
      |> Path.join("**/**/*.efxtmp")
      |> Path.wildcard()
    end
    |> List.flatten()
    |> Enum.each(fn path ->
      IO.puts(path)
      original_path = String.replace_trailing(path, ".efxtmp", "")
      IO.puts(original_path)
      File.rm!(original_path)
      File.rename(path, original_path)
    end)
  end
end

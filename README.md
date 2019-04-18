# Efx - First class side effects for Elixir
Experimental Elixir language extension adding support for **First class effects**. Otherwise known as **algebraic effects**[1][2]

# Marking effects

```elixir
eff print() :: {IO.puts/1}
def print() do
  IO.puts "Something"
end
```

# Defining own effects

```elixir
defeffect Example.print()
```

Now this is an effect and can be reasoned about on its own. It also is an alias to itself
and all the underlying effects. What it means is that used like

`eff fun() :: {Example.print/0}`

Where `Example.print()` contains effects `IO.puts/1` and `IO.read/1`
What is really represents is `{Example.print/1, IO.puts/1, IO.read/1}`
And each and everyone of these effects can be captured independently
Think of effects as call to functions that are identified as effect-full

# Capturing effects
Effects can be captured using a dedicated syntax `handle do...catch...end`
```elixir
handle do
  Example.print()
catch
  # Here we can replace our call with anything different. Let's forbid our IO.puts
  # from printing any passwords
  IO.puts(arg1) ->
    if arg1 =~ "password" do
      :ok
    else
      IO.puts(arg1)
    end

  # But lets get rid of all writes whatsoever
  IO.write(arg) ->
    :ok
end
```
Said handler *purifies* the body of the selected effect, but also augments it with all effects mentioned in the handler's body. Because we don't know what values the function can take we always assume the most pessimistic eventuality.
Hence, in this example results of our code block are purified from the `IO.write/1` effect; but not purified of `IO.puts/1` effect (because it can still be emitted under specific circumstances)

# Effect inference
To maintain a controllable system in which the effects are values derived from the code it's imperative to be able to check correctness of effect annotations. Due to [almost] all of the information available at compile time, it is possible to implement an algorithm similar to Hindley-Milner type inference to determine all of the effects and verify their corresponding annotations. For the sake of simplicity it is referred as `event-checking` in the rest of the documentation.

### Example of a compile-time effect-checking error
``` elixir
eff print() :: {} # <- This indicates pure computation
def print() do
  IO.puts "Something"
end

# Efx: Compile error at ./lib/example.ex:1
# Effect annotation for function Example.print/1 suggest it's a pure function.

# 1  defmodule Example do
# 2  eff print :: {}
# 3  def print() do

# But the definition says its effects are {IO.puts/1}
```
### Example of compile-time effect-checking inference
```elixir
def print() do
  File.read "file"
  |> IO.puts
end

eff test() :: {IO.puts/1}
def test() do
  print()
end

# Efx: Compile error at ./lib/example.ex:8
# Effect annotation for function Example.print/1 suggest it emits
# {IO.puts/1}

# 7
# 8  eff test :: {}
# 9  def test() do

# But the definition says its effects are {IO.puts/1, File.write/1}
```

# Explicit Effect control
When you require a part of code to be explicitly effect controlled out of your codebase you can use `effects do...end` construct. Which asserts all of the code is handled by Efx.

### Example
```elixir
  effects do

    test "Make sure the code is pure" do
      # This construct will be effect-checked even though out of main project's source-files
      IO.puts "A"
    end

  end
end

```

# Difficulties
## Inference of functions sent as messages
Erlang's processes system allows to send an anonymous function as a regular value to the process via `Process.send/2`. This proves impossible to figure out effects of a function at compile time if it receives an effect-full function via message passing.



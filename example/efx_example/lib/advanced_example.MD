
  # Feature 1: marking effects

  ```ruby
  eff print() :: {IO.puts/1}
  def print() do
    IO.puts "Something"
  end
  ```

  # Feature 2: Defining own effects

  Now this is an effect and can be reasoned about on its own. It also is an alias to itself
  and all the underlying effects. What it means is that used like
  eff fun() :: {AdvancedExample.print/0}
  Where AdvancedExample.print() contains effects IO.puts and IO.read
  What is really represents is {AdvancedExample.print/1, IO.puts/1, IO.read/1}
  And each andd everyone of these effects can be captured independently

  ```ruby
  defeffect AdvancedExample.print()
  ```




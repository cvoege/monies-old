defmodule MoniesTest do
  use ExUnit.Case
  doctest Monies

  test "greets the world" do
    assert Monies.hello() == :world
  end
end

defmodule Holding do
  fields = [:ticker, :value]
  @enforce_keys fields
  @derive {Jason.Encoder, only: fields}
  defstruct fields
end

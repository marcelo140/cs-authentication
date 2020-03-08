defmodule Mix.Tasks.Auth.Gen.Secret do
  use Mix.Task
  
  @shortdoc "Generates a new secret with 64 bytes"

  @impl Mix.Task
  def run(_args) do
    random_string(64) |> Mix.shell().info()
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)
  end
end


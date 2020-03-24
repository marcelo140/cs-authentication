defmodule AuthAuthorizator do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{private: %{authenticate: true}} = conn, _opts) do
    if is_nil(conn.assigns[:user]) do
        conn |> deny_authorization
    else
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp deny_authorization(conn) do
    conn
    |> send_resp(401, "No permissions for this page!")
    |> Plug.Conn.halt()
  end
end

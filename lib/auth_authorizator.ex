defmodule AuthAuthorizator do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{private: %{authenticate: true}} = conn, _opts) do
    session = conn |> get_session("id") |> AuthSession.from_session

    case is_nil session do
      true -> 
        conn |> deny_authorization
      false -> 
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

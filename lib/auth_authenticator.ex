defmodule AuthAuthenticator do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user = conn |> get_session("id") |> AuthSession.from_session || 
      conn.cookies["jwt"] |> AuthJWT.verify

    conn |> assign(:user, user)
  end
end

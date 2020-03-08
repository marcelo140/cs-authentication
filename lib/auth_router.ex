defmodule AuthRouter do
  use Plug.Router

  plug :put_secret_key_base

  plug Plug.Session,
    store: :cookie,
    key: "_notetaker_key",
    signing_salt: "asdaa9sd80a980asd"

  plug :match
  plug :dispatch

  use Plug.ErrorHandler

  get "/" do
    name = case conn |> fetch_session |> get_session("id") |> AuthSession.from_session do
      nil -> "?? Wait, who the heck are you?"
      name -> name
    end

    conn |> send_resp(200, "Hello #{name}")
  end

  get "/login/:name" do
    session_id = AuthSession.create_session(name)    

    conn 
    |> fetch_session 
    |> put_session("id", session_id)
    |> redirect_to("/")
  end

  get "/logout/" do
    conn 
    |> fetch_session 
    |> get_session("id")
    |> AuthSession.destroy_session()

    conn |> fetch_session |> clear_session |> redirect_to("/")
  end

  get "/admin" do
    :authorized = requires_authorization(conn)

    send_resp(conn, 200, "Welcome home")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp put_secret_key_base(conn, _) do
    put_in conn.secret_key_base, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end

  defp redirect_to(conn, path) do
    conn
    |> put_resp_header("location", path)
    |> send_resp(301, "")
  end

  defp requires_authorization(conn) do
    session = conn
    |> fetch_session
    |> get_session("id")
    |> AuthSession.from_session

    case is_nil session do
      false -> :authorized
      true -> :unauthorized
    end
  end
end

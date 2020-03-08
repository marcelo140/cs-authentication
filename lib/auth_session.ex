defmodule AuthSession do
  @opts [
    hostname: "localhost",
    username: "postgres",
    password: "postgres",
    database: "auth_dev"
  ]

  @find_user_q "SELECT id FROM users WHERE username = $1"

  @find_session_q "SELECT id FROM sessions WHERE user_id = $1"

  @create_session_q "INSERT INTO sessions (user_id) VALUES ($1)"

  @delete_session_q "DELETE FROM sessions WHERE id = $1"

  @list_sessions_q "SELECT sessions.id, username FROM sessions
    INNER JOIN users ON users.id = user_id"

  @user_from_session_q "SELECT username FROM sessions
    INNER JOIN users ON users.id = user_id
    WHERE sessions.id = $1"

  def create_session(name) do
    {:ok, conn} = Postgrex.start_link(@opts)

    user_id = Postgrex.query!(conn, @find_user_q, [name]).rows
    |> hd |> hd

    Postgrex.query!(conn, @create_session_q, [user_id])
    Postgrex.query!(conn, @find_session_q, [user_id]).rows
    |> hd |> hd
  end

  def from_session(id) do
    {:ok, conn} = Postgrex.start_link(@opts)

    Postgrex.query!(conn, @user_from_session_q, [id]).rows
    |> Enum.at(0)
  end

  def destroy_session(id) do
    {:ok, conn} = Postgrex.start_link(@opts)

    Postgrex.query!(conn, @delete_session_q, [id])
  end

  def list_sessions do
    {:ok, conn} = Postgrex.start_link(@opts)

    Postgrex.query!(conn, @list_sessions_q, []).rows
  end
end


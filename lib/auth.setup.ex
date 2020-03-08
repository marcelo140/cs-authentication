defmodule Mix.Tasks.Auth.Setup do
  use Mix.Task
  
  @shortdoc "Creates database with some users"

  @impl Mix.Task
  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:postgrex)

    opts = [
      hostname: "localhost",
      username: "postgres",
      password: "postgres",
      database: "postgres"
    ]

    {:ok, conn} = Postgrex.start_link(opts)

    Postgrex.query!(conn, "DROP DATABASE auth_dev", [])
    Postgrex.query!(conn, "CREATE DATABASE auth_dev", [])

    opts = [
      hostname: "localhost",
      username: "postgres",
      password: "postgres",
      database: "auth_dev"
    ]

    {:ok, conn} = Postgrex.start_link(opts)

    Postgrex.query!(conn, "CREATE TABLE users (id SERIAL PRIMARY KEY, username TEXT)", [])
    Postgrex.query!(conn, "CREATE TABLE sessions (id SERIAL PRIMARY KEY, user_id integer REFERENCES users)", [])
    Postgrex.query!(conn, "INSERT INTO users (username) VALUES ('escolhido'), ('marcelo')", [])
  end
end

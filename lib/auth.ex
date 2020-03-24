defmodule Auth do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, 
        scheme: :http,
        plug: AuthRouter,
        options: [port: 4000]},
    ]

    AuthJWT.start_link([
      {:secret_key_base, Application.get_env(:auth, :secret_key_base)},
      {:signing_salt, Application.get_env(:auth, :signing_salt)}
    ])

    opts = [strategy: :one_for_one, name: Auth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end


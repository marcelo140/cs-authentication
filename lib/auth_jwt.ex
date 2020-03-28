defmodule AuthJWT do
  use Agent

  def start_link(opts) do
    secret_key_base = Keyword.fetch!(opts, :secret_key_base)
    signing_salt = Keyword.fetch!(opts, :signing_salt)

    jwk = Plug.Crypto.KeyGenerator.generate(secret_key_base, signing_salt)
    |> JOSE.JWK.from_oct

    Agent.start_link(fn -> jwk end, name: __MODULE__)
  end

  def generate_jwt(subject) do
    jwk = Agent.get(__MODULE__, & &1)
    jose_header = %{ "alg" => "HS256"}
    payload = %{ "iss" => "auth_app", "sub" => subject, "exp" => next_minute_timestamp() }

    JOSE.JWT.sign(jwk, jose_header, payload) |> JOSE.JWS.compact |> elem(1)
  end

  def verify(jwt) do
    case verify_signature(jwt) do
        {user, timestamp} -> 
          if timestamp < DateTime.utc_now |> DateTime.to_unix do
            user
          else
            nil
          end
        _ ->
          nil
    end
  end

  defp verify_signature(jwt) do
    jwk = Agent.get(__MODULE__, & &1)

    case JOSE.JWT.verify(jwk, jwt) do
      {true, %JOSE.JWT{fields: %{"sub" => user, "exp" => timestamp}}, _header} ->
        {user, timestamp}
      _ ->
        nil
    end
  end

  defp next_minute_timestamp do
    DateTime.utc_now |> DateTime.add(60) |> DateTime.to_unix
  end
end


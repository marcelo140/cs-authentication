# Auth

## todo

implement expiration

This was done for the sole purpose of understanding authentication and comparing cookies with JWTs.

# Some notes from what I understand right now:

- cookies are stateful, they require the server to save the match between the sessionId and the user
- JWTs are stateless, you can simply validate the JWT and accept the user claims
- JWTs are more CPU intensive since they need to be decrypted
- JWTs are supposed to be issued for single time use or a very short amount of time, how do they keep the client from re-authenticating all the time?
- If a sessionId gets compromised, you can remove it from the DB, denying the intruder the chance to abuse it.
- If a JWT is compromised, there's no way to invalidate it! Your only chance is to have a blacklist of JWTs that should be denied while they don't expire. This goes against the only benefit I found so far for JWTs: being stateless and thus avoiding round-trips to the database.

- Unlike cookies, they're can be shared cross-domain. This allow them to be used for single sign-on.

# Notes about JWT:

- can be done with public/private key or HMAC. wtf is HMAC?

- A JWT can take one of two forms:

  - JSON Web Signature (JWS) -> signed (can check for integrity ; not secure to share private information)
  - JSON Web Encryption (JWE) -> encrypted (can protect private information)

- with public/private key, a signed token certifies that it was signed by the party holding the private key
- it is widely used for authorization, specifically for Single Sign On because it can be user across different domains (cookies can't)

HMAC use octet keys
! What are octet keys?

## Form

- header: JSON Object Signing and Encryption (JOSE)
- signature = algorithm(bheader.bpayload, secret)
- token: base64(header).base64(payload).signature

easier to state horizontally (?) -> it's stateless (if it is), so it is not dependent on the database
blogger claims redis + sessions is easier to scale up

you don't control the expiration mechanism (as in JWT)
data in the JWT claims can go become outdated (as in caches)

> JWTs represent a set of claims as a JSON object that is encoded in a JWS and/or JWE structure.

what is a JWS / JWE?

> The contents of the JOSE Header describe the cryptographic operations applied to the JWT Claims Set.

Never heard about this JOSE header. where does it fit?

# Session

When passing through Plug.Session:

- put {:plug_session_fetch, fetch_session(config)} into conn.private

When fetching the session:

1. Plug.Conn parses the request cookies headers
2. Gets the function in :plug_session_fetch [fetch_session(config)] and applies it to the connection
3. Plug.Session picks the session using the key set in the configuration and passes it to the session store for it to decode
4. The cookie store verifies/decrypts the session
5. The session is set in :plug_session
6. The :plug_session_fetch is replaced with :done to avoid repeating the work (fetching the session is lazy)

# Signing

signing_salt
secret_key_base
opts(iterations, ...)
----> all used to generate secret key
! what happens here to generate the key?

cookie X.Y.Z where
X = b64(protected) --> HS256 is default
Y = b64(payload)
Z = b64(signature)

`if hmac(:sha256, key, X.Y) = Z, do: payload`

! how does hmac use the hashing algorithm to do its thing?

! if it uses a secret, why is it different than encrypting?

    - the message is just encoded in base64, not hidden in any way

what properties do encryption algorithms have that signing don't if you still require a secret to sign/verify?

## HMAC

SHA-2: - md5-like structure; - merkle-damgard structure -> susceptible to length extension attacks - one-way compression function; - davies-meyer structure

SHA-3: Keccak family

sha-256 operates over 512-bit blocks (32 bytes). Its output is usually represented in hexadecimal and thus have 64 digits.

As a consequence (of what) the algorithm provides better immunity against length extension attacks (what are these atacks?)

there seems to be a difference between digitally signing and MACing

## Differences between digital signatures and MAC

- In the case of MACs, the MAC key needs to be in the hands of everyone who needs to perform integrity computation and checking. As such, MAC only provide origination if there are only two parties holding the key and one of them is aware that it didn't sign the key.

! How doe JWS provide authentication? And how does it provide integrity without sharing the key?
because it can use asymetric algorithms

JWS Format

- JOSE header
- JWS payload
- JWS signature

# Notes about this elixir implementation:

- The session store requires the connection to have a secret_key_base. What is its purpose?
- The session store requires the connection to have a signing_salt. What is its purpose?
- Why does it need both a secret_key_base and a signing_salt?

TO GENEREATE THEY SECRET KEY! HOW DOES THE KEY GENERATOR WORK?

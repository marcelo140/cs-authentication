# Auth

## todo

implement expiration

This was done for the sole purpose of understanding authentication and comparing cookies with JWTs.

Some notes from what I understand right now:

- cookies are stateful, they require the server to save the match between the sessionId and the user
- JWTs are stateless, you can simply validate the JWT and accept the user claims
- JWTs are more CPU intensive since they need to be decrypted
- JWTs are supposed to be issued for single time use or a very short amount of time, how do they keep the client from re-authenticating all the time?
- If a sessionId gets compromised, you can remove it from the DB, denying the intruder the chance to abuse it.
- If a JWT is compromised, there's no way to invalidate it! Your only chance is to have a blacklist of JWTs that should be denied while they don't expire. This goes against the only benefit I found so far for JWTs: being stateless and thus avoiding round-trips to the database.

Notes about JWT:

- can be done with public/private key or HMAC. wtf is HMAC?
- there is a distinction between encrypted and signed tokens. Encryption hides the information, signing allows to check for integrity. What exactly is signing?
- with public/private key, a signed token certifies that it was signed by the party holding the private key
- it is widely used for authorization, specifically for Single Sign On because it can be user across different domains (cookies can't)
- token: base64(header).base64(payload).signature
- signature = algorithm(bheader.bpayload, secret)

easier to state horizontally (?) -> it's stateless (if it is), so it is not dependent on the database
blogger claims redis + sessions is easier to scale up

you don't control the expiration mechanism (as in JWT)
data in the JWT claims can go become outdated (as in caches)

Notes about this elixir implementation:

- The session store requires the connection to have a secret_key_base. What is its purpose?
- The session store requires the connection to have a signing_salt. What is its purpose?
- Why does it need both a secret_key_base and a signing_salt?

## Installation

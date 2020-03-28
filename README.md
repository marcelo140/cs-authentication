# Auth

This is a toy project to understand some authorization concepts and raise further questions for myself. Two different authorization methods are implemented: sessions and JWTs. No authentication is done.

## Authorization

### Sessions

Sessions are a means for the user to prove his identity with a server without having to authenticate all the time. The user authenticates once and the server provides him with a session ID. Everytime the user wants to reach the server he sends him his session ID to identify himself, avoiding the hassle of authentication. Note that the server needs to keep a mapping from sessions to users, sessionID -> user. When the user logs in we add the entry to the map, when the user logs out we remove the entry.

The sessionID is usually saved in the browser local storage to be fetched between visits. The session should be signed to guarantee it was issued by the server and not created by a malicious user pretending to be someone else.

#### Elixir implementation

1. When the connection passes through Plug.Session, a lambda function that fetches the session is stored in it. Plug.Session requires a secret\_key\_base and a signing\_salt to be defined. These are used to generate a secret for signing. Encryption is also an option but I decided to stick to signing.

2. Once we fetch the session in the connection the following happens

    2.1. Plug.Conn parses the cookies in the request headers

    2.2. Calls the lambda function that was previously stored which calls Plug.Session

    2.2. Plug.Session fetches the session cookie session that was parsed in 2.1 and calls Plug.Session.Store for it to verify the session integrity

    2.4. The cookie store generates the secret key using the secret\_key\_base and signing\_salt and verifies the session, retrieving its contents

    2.5. The session is set in :plug_session

    2.6. The lambda function in the connection is replaced with :done. Further calls will return immediately, as the session was already fetched. This is a case lazy evaluation.

The algorithm used to sign and verify the session is HS256. For this reason, when using JWTs I decided to also stick to HS256.

> How are the secret\_key\_base and the signing\_salt used to generate the key?

### JWK, JWA, JWS, JWE and JWTs

I found the concept of JWTs quite recently while working on another project. I already used Single Sign On before, but had no idea of how it actually worked. After workign with it in the this new project my grasp of it was still limited: the user sends the JWT and the server uses the JWK to verify its authenticity. I didn't really understand its inner workings and where it differred from sessions. I didn't even understood how signing actually worked. This is why I decided to start this toy project.

At first I was quite overwhelmed with all the acronyms. I was only interested in learning JWKs and JWTs and I'd never heard about the others so where were all coming from? After reading RFCs for JWK, JWS, JWT and skimming JWA for reference, this is what I came up with. Note that there are way more (optional) parameters than the ones I present.

#### JWK

A **JSON Web Key** represents a single cryptographic key or a set of cryptographic keys. The cryptographic algorithms that are supported by the JWK are defined by the JSON Web Algorithms specification. These keys are used in the JSON Web Signature and JSON Web Encryption specifications.

```json
{
    "kty": "oct",
    "v": "741c8ce2f636bb9e2"
}
```

The only mandatory parameter in the JWK is the key type **kty** that states the algorithm family used by the key. Other parameters are then required depending on the chosen algorithm family. For the key type `oct`, the JWA standard defines the key value parameter **v** as the base64url representation of the key. Many other parameters are described by the specification.

> Do the oct algorithm family have any interesting properties? Is it simply binary? Good question. Didn't take a look yet.

#### JWS

A **JSON Web Signature** represents content that was secured through digital signatures (e.g. ECDSA algorithm) or Message Authentication Codes (e.g. HMAC algorithm). This allow us to perform integrity and possibly authorization checks on the message. The following is an example of a JWS in it's compact form.

```
eyJhbGciOiJIUzI1NiJ9Cg==.TyBlc2NvbGhpZG8gw6kgbmFibw==.40d1b895fcdae516ed19f70ae7c4ec862bc7a2d5b0963952eab4dda8031c030f
```

What information can we take from this? If we split it by the dots, we see three different parts. These are (1) the JWS Header in base64url representation (2) the payload in base64url representation (3) the signature obtained from signing the first two parts.

So lets start decoding the message.

```
> echo -n "eyJhbGciOiJIUzI1NiJ9Cg==" | base64 -d
{"alg":"HS256"}
```

The JWS Header tells us that the algorithm used to sign the message was `HS256` i.e. HMAC with the hash function SHA-256. What about the payload?

```
> echo -n "TyBlc2NvbGhpZG8gw6kgbmFibw==" | base64 -d
O Escolhido é nabo
```

Ok, clearly messed up. How do we confirm that someone tampered with the message? We simply use the algorithm described in the JWS Header to compute the Message Authentication Code of the first two parts and check if it's the same signature we received. Lets try.

As we saw, the algorithm used is HS256. This algorithm requires a key that must be kept secret so that a 3rd party can't sign messages. The key used to sign this message was the one in the JWK example, so lets compute the MAC with it and see if it the signatures match.

```
> echo -n "eyJhbGciOiJIUzI1NiJ9Cg==.TyBlc2NvbGhpZG8gw6kgbmFibw==" | hmac256 "741c8ce2f636bb9e2"
d661582b2b5107d84aa4503a75cece9590edfa26ca4a87e6265232d13aec26ed
```

The signatures don't match... This means someone tampered with the message. Note that the payload wasn't encrypted, we just had to decode the message. If we wanted to send private information in the payload, we would have to rely on JSON Web Encryption. I had no interest interest in JWEs so I didn't look anything about it.

#### JWT

Only JWTs are missing now... JWTs are a way to represent claims between two-parties in a compact and url-safe manner. These claims are JSON object that are encoded in base64url to be used as JWS payloads. 

```json
{
    "iss": "AuthApp",
    "sub": "Escolhido",
    "exp": 1585259296
}
```
This is an example of a claim set. The issuer claim **iss** identifies the party that issued the JWT, in this case `AuthApp`. The subject claim **sub** identifies the subject we're making claims about. The expiration time claim **exp** identifies the time on after which the JWT must not be accepted. 

When a user authenticates himself we can issue him a JWT like this. He can then use it to prove his identity without having to authenticate every time. Once the JWT expires, the user will have to authenticate again and we provide him with a new JWT.

### What did I learn here?

Sessions are stateful, they require the server to save the mapping between the sessionId and the user. Everytime we receive a request we'll have to hit the database for the session. This has the potential to become a bottleneck in a large application. You may require a service on its own dedicated to handle sessions which will be adding complexity and subject to potential falures.

JWTs are stateless, as long as you have the key you'll be able to verify the JWT and validate the user claims. Your infrastucture will be simpler and more resilient and you may be able to save some latency.

> It would be interesting to try to force these problems to emerge (even if they don't) on a toy app.

On the other hand, with sessions if a user session ever gets compromised we simply need to remove it to deny access to potential malicious user. JWTs, however, remain valid until its expiration time. One possible way to deny access to compromised JWTs would be to keep a blacklist of JWTs, but that would mean we would have to keep state, defeating the previous point. Another possible way would be to refresh the secret key used to sign and validate the JWTs, rendering all previously issued JWTs as invalid. This doesn't seem feasible in most applications.

> JWTs are also usually used to perform cross-domain authentication through Single Sign On. It would be interesting to take a look at OAuth or OpenID.

## HMAC

HMAC is mechanism for message authentication using cryptographic hash functions. It can be used with any iterative hash function in combination with a secret key. Examples of iterative hash functions are md5, SHA-1, SHA2 and SHA-3. Both md5 and SHA-1 are considered unsecure for cryptographic use.

> How do iterative hash functions work? And how do non-iterative hash functions work? Might be nice to check this.

What got me to searching about HMAC was a simple question: what properties does it have that can't be obtained just with the hash function and the secret? What is it adding? 

If we consider a generic hash-function H, a secret S and a message M, HMAC can be computed as
```
H(K || H(K || message))
```
where || denotes concatenation. Note that I'm omitting details like key size and key padding.

So why can't we simply `H(K || message)`? Apparently this would make us vulnerable to a length-extension attack. SHA-256 takes a message as input and uses this input to transform its internal state. When the input ends, it outputs its internal state as the hash digest. Thus, if we wish to extend the original message and generate a valid MAC that would be accepted by the server, we simply needed to use the previous digest as the initial internal state for SHA-256 and process our additional input, without even knowing the original secret key.

There is an addional caveat here. SHA-256 breaks the input into multiple 512 bits blocks. If the last block is smaller than 512 bits, it will be padded to fit a 512 bits block. So SHA-256 will actually be hashing `K || message || padding`. Since the padding was used to calculate our initial digest, we need to know how long it is to replicate it in our extended message. Since we know the message's length, to calculate the length of the padding we just need to discover the secret's length which can be done through brute-force. Our extended message would look like `original_message || padding || our_message`.

HMAC avoid this by hashing the output of `H(K || message)` again, making it impossible to extend. Both md5, SHA-1 and SHA-2 are vulnerable to this attack because they are all based on Merkle-Damgard constructions. SHA-3, oh the other had, is based on a Keccac cryptographic sponge which is not vulnerable to this attack. In the case of SHA-3, H(K || message) would be safe against length-extension attacks.

> Nope, I don't know anything about Merkle-Damgard constructions or Keccac sponges. That's something to explore in the future.

## Base64

This one is actually shameful. One of these nights I was thinking to myself "Base64 sure is used in a lot of places... How does this encoding actually work??". Wait. It's called base64. Could it really be just another base like binary, decimal and hexadecimal?

Humm, base16 has 16 different digits and it take 4 bits to represent each digit. Then base64 with its 64 characters would take 6 bits to represent. A byte has 8 bits though, so how many digits would it take to make a multiple of 8? 4 digits. You need 4 base64 digits, taking 24 bits, to represent 3 bytes of information. What if the binary string we want to represent isn't a multiple of 4 though? Ohhh, that's what the padding is for. Duh. That's why you never have more than 3 equal signs (=) in a base64.

I still had another question though. The alphabet has 26 letters. So uppercase letters + lowercase letters + 10 digits = 62 characters. What are the other 2 characters used in base64. Turns out it's "/" and "+". But since these characters have a special meaning in URLs there's also base64url that uses "-" and "\_" intead to be url-safe.

This sure took me a lot of years to realize.


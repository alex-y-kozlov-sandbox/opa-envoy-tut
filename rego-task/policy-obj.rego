package envoy.authz

import input.attributes.request.http as http_request

default allow = false

token = {"valid": valid, "payload": payload} {
    [_, encoded] := split(http_request.headers.authorization, " ")
    [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
}

role_2_permission := {
    "guest": [{"verb": "GET", "api": "/people*", "condition": true }],
    "admin": [
      {"verb": "GET", "api": "/people*", "condition": true },
      {
        "verb": "POST", "api": "/people", 
        "condition": user_self == false # (not user_self) doesnt work. Didn't find proper syntax. using == false
      },
      {"verb": "DELETE", "api": "/people*", "condition": true }
    ]
}

user_self = true {
  name := object.get(object.get(input, "parsed_body", {}),"firstname","")
  lower(name) == base64url.decode(token.payload.sub)
} else = false 

allow {
    is_token_valid
    action_allowed
}

is_token_valid {
  token.valid
  now := time.now_ns() / 1000000000
  token.payload.nbf <= now
  now < token.payload.exp
}


action_allowed {
  some perm_index
  role = role_2_permission[ token.payload.role ]
  role[ perm_index ].verb == http_request.method
  glob.match(role[ perm_index ].api, [], http_request.path)
  role[ perm_index ].condition
}

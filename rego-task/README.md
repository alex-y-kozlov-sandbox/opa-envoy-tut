## What is it?

This repo is based on the Open Policy Agent [Stand-alone Envoy Tutorial](https://www.openpolicyagent.org/docs/latest/envoy-tutorial-standalone-envoy/) and updates policy file tio enable DELET operation for the 'admin' users

This folder contains 3 files:

- `policy.rego` - policy defined without permission object (inline)
- `policy-obj.rego` - policy with the permission object
- `policy-obj_test.rego` - policy test file

## Prerequisites

You will need to open policy agent (opa) installed on your machine.
All CLI commands on this page asume you are using Mac.

Install Open Policy Agent:

```sh
brew install opa
```

## What's in the permission object?

Permission object defines permissions as follows:

- for a given role (such as admin, guest, etc.)
- specify a list of permitted HTTP methods and paths and a custom eval condition

Example of a custom eval condition is "A user cannot add him or herself"

Below is a permission object that defines required permissions:

```rego
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
```

`user_self` is a predicate that implements a custom condition as follows:
```rego
user_self = true {
  name := object.get(object.get(input, "parsed_body", {}),"firstname","")
  lower(name) == base64url.decode(token.payload.sub)
} else = false 
```

## How to run tests?

To test object-based policy run:
```sh
opa test policy-obj.rego policy-obj_test.rego
```

To test inline policy run:
```sh
opa test policy.rego policy-obj_test.rego
```

Both should produce identical results
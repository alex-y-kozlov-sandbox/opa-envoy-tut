package envoy.authz

test_user_get {
    allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiZ3Vlc3QiLCJzdWIiOiJZV3hwWTJVPSIsIm5iZiI6MTUxNDg1MTEzOSwiZXhwIjoxNjQxMDgxNTM5fQ.K5DnnbbIOspRbpCr2IKXE9cPVatGOCBrBQobQmBmaeU"
                  },
                  "method": "GET",
                  "path": "/people"
              }
          }
      }
    }
}

test_user_delete_denied {
    not allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiZ3Vlc3QiLCJzdWIiOiJZV3hwWTJVPSIsIm5iZiI6MTUxNDg1MTEzOSwiZXhwIjoxNjQxMDgxNTM5fQ.K5DnnbbIOspRbpCr2IKXE9cPVatGOCBrBQobQmBmaeU"
                  },
                  "method": "DELETE",
                  "path": "/people"
              }
          }
      }
    }
}

test_anonymous_get_denied {
    not allow with input as 
    {
      "attributes": {
          "request": {
              "http": {
                  "method": "GET",
                  "path": "/people"
              }
          }
      }
    }
}

test_admin_post {
    allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"
                  },
                  "method": "POST",
                  "path": "/people",
                  "body":"{\"firstname\":\"Joe\", \"lastname\":\"Smith\"}"
              }
          }
      },
      "parsed_body":{"firstname": "Joe", "lastname": "Smith"}
    }
}

test_admin_self_post_denied {
    not allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"
                  },
                  "method": "POST",
                  "path": "/people",
                  "body":"{\"firstname\":\"Bob\", \"lastname\":\"Rego\"}"
              }
          }
      },
      "parsed_body":{"firstname": "Bob", "lastname": "Rego"}
    }
}

test_admin_put {
    not allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"
                  },
                  "method": "PUT",
                  "path": "/people"
              }
          }
      }
    }
}

test_admin_delete {
    allow with input as
    {
      "attributes": {
          "request": {
              "http": {
                  "headers": {
                      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"
                  },
                  "method": "DELETE",
                  "path": "/people"
              }
          }
      }
    }
}
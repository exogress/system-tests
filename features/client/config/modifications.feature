Feature: modifications

  Scenario: Modify headers of requests
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: modifications
mount-points:
  default:
    handlers:
      dir:
        kind: proxy
        upstream: upstream
        priority: 10
        rules:
          - filter:
              path: ["*"]
            action: invoke
            modify-request:
              headers:
                insert:
                  "x-inserted": "yes"
                  "x-sent-from-client3": "rewrite"
                append:
                  "x-sent-from-client2": "appended"
                remove:
                  - "x-sent-from-client"
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/" with status-code "200" and body "root"
    And I request GET "/" with headers
      | header              | value |
      | x-sent-from-client  | true  |
      | x-sent-from-client2 | true  |
      | x-sent-from-client3 | true  |
    Then upstream request header "x-sent-from-client" was not set
    And upstream request header "x-inserted" was "yes"
    And upstream request header "x-sent-from-client2" was "true|appended"
    And upstream request header "x-sent-from-client3" was "rewrite"


  Scenario: Template in header values
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: disallowed
mount-points:
  default:
    handlers:
      proxy:
        kind: proxy
        upstream: upstream
        priority: 10
        rules:
          - filter:
              path: ["?"]
            action: invoke
            modify-request:
              headers:
                insert:
                  "x-header": "Requested: {{ 0 }}"
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/req-path" with status-code "200" and body "p"
    And I request GET "/req-path"
    Then I should receive a response with status-code "200"
    And upstream request header "x-header" was "Requested: req-path"

  Scenario: Modify response
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: modifications
mount-points:
  default:
    handlers:
      dir:
        kind: proxy
        upstream: upstream
        priority: 10
        rules:
          - filter:
              path: ["*"]
            action: invoke
            on-response:
              - when:
                  status-code: "200"
                modifications:
                  headers:
                    remove:
                      - "x-a"
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    Then upstream server responds to "/not-match" with status-code "201" and body "root" with headers
      | header | value |
      | x-a    | yes   |
    And upstream server responds to "/" with status-code "200" and body "root" with headers
      | header | value |
      | x-a    | yes   |
    When I request GET "/not-match"
    Then header "x-a" is "yes"
    When I request GET "/"
    Then header "x-a" is not set


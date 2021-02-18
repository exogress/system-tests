Feature: redirect

  Scenario: Redirect
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      main:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["url-str"]
            action: respond
            static-response: redirect-to-url-str
          - filter:
              path: ["url-arr"]
            action: respond
            static-response: redirect-to-url-arr
          - filter:
              path: ["path"]
            action: respond
            static-response: redirect-to-same-arr
static-responses:
  redirect-to-url-str:
    kind: redirect
    destination: "https://google.com/a/b?q=1"
    redirect-type: moved-permanently
  redirect-to-url-arr:
    kind: redirect
    destination: ["https://google.com", "a"]
    redirect-type: see-other
  redirect-to-same-arr:
    kind: redirect
    destination: ["a", "b"]
    redirect-type: multiple-choices
"""
    When I spawn exogress client

    And I request GET "/url-str"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/a/b?q=1"
    And I request GET "/url-arr"
    Then I should receive a response with status-code "303"
    And header "Location" is "https://google.com/a"
    And I request GET "/path"
    Then I should receive a response with status-code "300"
    And header "Location" is "/a/b"

  Scenario: Redirect with templating
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      main:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["relative", "?"]
            action: respond
            static-response:
              kind: redirect
              destination: ["p-{{ 1 }}"]
              redirect-type: moved-permanently
          - filter:
              path: ["with-domain", "?"]
            action: respond
            static-response:
              kind: redirect
              destination: ["https://google.com", "a-{{ 1 }}-b"]
              redirect-type: moved-permanently
          - filter:
              path: ["with-query-single"]
              query-params:
                q: "?"
            action: respond
            static-response:
              kind: redirect
              destination: ["https://google.com", "{{ q }}"]
              redirect-type: moved-permanently
          - filter:
              path: ["with-query-path"]
              query-params:
                q: "*"
            action: respond
            static-response:
              kind: redirect
              destination: ["https://google.com", "{{ q }}"]
              query-params:
                strategy: remove
              redirect-type: moved-permanently
          - filter:
              path: ["with-query-to-query"]
              query-params:
                q1: "?"
            action: respond
            static-response:
              kind: redirect
              destination: ["https://google.com", "a"]
              query-params:
                strategy: remove
                set:
                  q: "{{ q1 }}"
              redirect-type: moved-permanently
          - filter:
              path: ["with-query-to-multiple", "*"]
            action: respond
            static-response:
              kind: redirect
              destination: ["https://google.com", "a"]
              query-params:
                strategy: remove
                set:
                  q: "{{ 1 }}"
              redirect-type: moved-permanently
"""
    When I spawn exogress client

    And I request GET "/relative/rel"
    Then I should receive a response with status-code "301"
    And header "Location" is "/p-rel"

    When I request GET "/with-domain/d"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/a-d-b"

    When I request GET "/with-query-path?q=a/b/c"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/a/b/c"

    When I request GET "/with-query-single?q=query"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/query?q=query"

    When I request GET "/with-query-to-query?q1=query"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/a?q=query"

    When I request GET "/with-query-to-multiple/a/b/c"
    Then I should receive a response with status-code "301"
    And header "Location" is "https://google.com/a?q=a/b/c"

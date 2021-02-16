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
    destination: "https://google.com"
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
    And header "Location" is "https://google.com/"
    And I request GET "/url-arr"
    Then I should receive a response with status-code "303"
    And header "Location" is "https://google.com/a"
    And I request GET "/path"
    Then I should receive a response with status-code "300"
    And header "Location" is "/a/b"

#    TODO: test redirect with matching
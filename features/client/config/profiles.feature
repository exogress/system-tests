Feature: profiles filtering

  Scenario: profiles
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      handler1:
        kind: pass-through
        profiles: ["p1"]
        priority: 10
        rules:
          - filter:
              path: ["only-p1"]
            action: respond
            static-response: p1
      handler2:
        kind: pass-through
        priority: 20
        rules:
          - filter:
              path: ["only-p2"]
            profiles: ["p2"]
            action: respond
            static-response: p2
          - filter:
              path: ["both"]
            profiles: ["p1", "p2"]
            action: respond
            static-response: both
static-responses:
  p1:
    kind: raw
    body:
      - content-type: text/plain
        content: "p1"
  p2:
    kind: raw
    body:
      - content-type: text/plain
        content: "p2"
  both:
    kind: raw
    body:
      - content-type: text/plain
        content: "p1-2"
"""
    When I spawn exogress client with profile "p1"
    And I request GET "/only-p1"
    Then I should receive a response with status-code "200"
    When I request GET "/only-p2"
    Then I should receive a response with status-code "404"
    When I request GET "/both"
    Then I should receive a response with status-code "200"

    When I stop running exogress client
    And I spawn exogress client with profile "p2"
    And I request GET "/only-p1"
    Then I should receive a response with status-code "404"
    When I request GET "/only-p2"
    Then I should receive a response with status-code "200"
    When I request GET "/both"
    Then I should receive a response with status-code "200"

    When I stop running exogress client
    And I spawn exogress client
    And I request GET "/only-p1"
    Then I should receive a response with status-code "404"
    When I request GET "/only-p2"
    Then I should receive a response with status-code "404"
    When I request GET "/both"
    Then I should receive a response with status-code "404"


Feature: facts

  Scenario: Facts are accessible from static-responses body via handlebars engine
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: modifications
mount-points:
  default:
    handlers:
      dir:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["*"]
            action: respond
            static-response: show-facts
static-responses:
  show-facts:
    kind: raw
    status-code: 200
    body:
      - content-type: text/html
        content: "{{ this.facts.mount_point_hostname }}"
        engine: handlebars
"""
    When I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And content is my_domain_name

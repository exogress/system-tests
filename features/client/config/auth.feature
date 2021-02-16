Feature: authentication (IAP)

  Scenario: Access is denied if auth is not provided
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      auth:
        kind: auth
        providers:
          - name: github
            acl:
              - allow: github-user
        rules:
          - filter:
              path: ["none"]
            action: next-handler
          - filter:
              path: ["*"]
            action: invoke
        priority: 10
"""
    When I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "307"
    And header "Location" is "/_exg/auth?url=%2F&handler=auth"
    And I request GET "/none"
    Then I should receive a response with status-code "404"

Feature: gcs

  Scenario: gcs (simple parsing)
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: test
mount-points:
  default:
    handlers:
      dir:
        kind: static-dir
        dir: "./dir"
        priority: 5
        rules:
          - filter:
              path: ["index.html"]
            action: invoke
      gcs:
        kind: gcs-bucket
        priority: 10
        bucket:
          name: my-test-bucket
        credentials: "@gcs-creds"
"""
    When I spawn exogress client
    When I create directory "dir"
    And I create file "dir/index.html" with content "index"
    And I request GET "/index.html"
    Then I should receive a response with status-code "200"
    And content is "index"


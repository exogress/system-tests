Feature: s3

  Scenario: S3 (simple parsing)
    Given Exofile content
"""
---
version: 1.0.0
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
      s3:
        kind: s3-bucket
        priority: 10
        bucket:
          name: my-test-bucket
          region: us-west-2
"""
    When I spawn exogress client
    When I create directory "dir"
    And I create file "dir/index.html" with content "index"
    And I request GET "/index.html"
    Then I should receive a response with status-code "200"
    And content is "index"


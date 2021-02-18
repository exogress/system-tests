Feature: static_dir handler should serve file from static directory

  Scenario: Serve static files
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      dir:
        kind: static-dir
        dir: "./dir"
        priority: 10
"""
    When I spawn exogress client
    And I request GET "/index.html"
    Then I should receive a response with status-code "404"
    When I create directory "dir"
    And I create file "dir/index.html" with content "67f38040-6532-11eb-8c2d-2ba6dd1076ad"
    And I request GET "/index.html"
    Then I should receive a response with status-code "200"
    And content is "67f38040-6532-11eb-8c2d-2ba6dd1076ad"

  Scenario: Serve static dirs with index.html
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      dir:
        kind: static-dir
        dir: "./dir"
        priority: 10
        rules:
          - filter:
              path: ["?"]
            modify-request:
              path: ["{{ 0 }}", "index.html"]
            action: invoke
"""
    When I spawn exogress client
    When I create directory "dir/post"
    And I create file "dir/post/index.html" with content "blog post"
    And I request GET "/post"
    Then I should receive a response with status-code "200"
    And content is "blog post"

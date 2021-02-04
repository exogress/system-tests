Feature: rebasing

  Scenario: Rebase is working
    Given Exofile content
        """
        ---
        version: 1.0.0-pre.1
        revision: 1
        name: static-dir
        mount-points:
          default:
            handlers:
              dir:
                kind: static-dir
                dir: "./dir"
                priority: 10
                base-path: ["base", "path"]
                replace-base-path: ["replaced"]
                rules:
                  - filter:
                      path: ["filtered"]
                    action: respond
                    static-response: filtered
                  - filter:
                      path: ["*"]
                    action: invoke
            static-responses:
              filtered:
                status-code: 200
                kind: raw
                body:
                  - content-type: "text/html"
                    content: "filtered"
        """
    When I spawn exogress client
    When I create directory "dir/replaced"
    And I create file "dir/replaced/index.html" with content "replaced-data"
    And I request GET "/base/path/index.html"
    Then I should receive a response with status-code "200"
    And content is "replaced-data"
    And I request GET "/base/path/filtered"
    Then I should receive a response with status-code "200"
    And content is "filtered"

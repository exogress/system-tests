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
        """
    When I spawn exogress client
    When I create directory "dir/replaced"
    And I create file "dir/replaced/index.html" with content "replaced-data"
    And I request GET "/base/path/index.html"
    Then I should receive a response with status-code "200"
    And content is "replaced-data"

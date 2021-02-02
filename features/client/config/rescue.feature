Feature: rescue for exceptions handling

  Scenario: Catch status-code
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
                rescue:
                  - catch: "status-code:404"
                    action: next-handler
              proxy:
                kind: proxy
                upstream: upstream
                priority: 10
        upstreams:
          upstream:
            port: 11988
        """
    When I spawn exogress client
    And I request GET "/index.html"
    Then I should receive a response with status-code "404"
    And upstream server responds to "/index.html" with status-code "200" and body "index-proxy"
    And I request GET "/index.html"
    Then I should receive a response with status-code "200"
    And content is "index-proxy"
    When I create directory "dir"
    And I create file "dir/index.html" with content "static-proxy"
    And I request GET "/index.html"
    Then I should receive a response with status-code "200"
    And content is "static-proxy"

  Scenario: Catch on mount-point
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
            rescue:
              - catch: "status-code:404"
                action: respond
                static-response: not-found
            static-responses:
              not-found:
                kind: raw
                status-code: 404
                body:
                  - content-type: text/html
                    content: "<html>Not found 404</html>"
        """
    When I spawn exogress client
    And I request GET "/not-existing"
    Then I should receive a response with status-code "404"
    And content is "<html>Not found 404</html>"

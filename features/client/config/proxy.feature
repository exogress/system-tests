Feature: proxy handler should proxy to upstream

  Scenario: Proxy to upstream, when it's not available
    Given Exofile content
        """
        ---
        version: 1.0.0-pre.1
        revision: 1
        name: proxy
        mount-points:
          default:
            handlers:
              proxy:
                kind: proxy
                upstream: upstream
                priority: 10
        upstreams:
          upstream:
            port: 12523
        """
    When I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "500"
    When Exofile content
        """
        ---
        version: 1.0.0-pre.1
        revision: 1
        name: proxy
        mount-points:
          default:
            handlers:
              proxy:
                kind: proxy
                upstream: upstream
                priority: 10
                rescue:
                  - catch: "exception:proxy-error:upstream-unreachable"
                    action: respond
                    status-code: 502
                    static-response: bad-gateway
        static-responses:
          bad-gateway:
            kind: raw
            status-code: 502
            body:
              - content-type: text/html
                content: Bad gateway as static response!
        upstreams:
          upstream:
            port: 12523
        """
    And I request GET "/"
    Then I should receive a response with status-code "502"
    And content is "Bad gateway as static response!"

  Scenario: Proxy to upstream, when it's available
    Given Exofile content
        """
        ---
        version: 1.0.0-pre.1
        revision: 1
        name: proxy
        mount-points:
          default:
            handlers:
              proxy:
                kind: proxy
                upstream: upstream
                priority: 10
        upstreams:
          upstream:
            port: 11988
        """
    When I spawn exogress client
    And upstream servers responds to "/" with status-code "200" and body "root"
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And content is "root"
    When upstream servers responds to "/headers" with status-code "200" and body "headers"
    And responds with header "x-my-header" equals to "yes"
    And I request GET "/headers"
    Then content is "headers"
    Then header "x-my-header" is "yes"

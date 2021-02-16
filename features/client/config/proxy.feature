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
    And upstream server responds to "/" with status-code "200" and body "root"
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And content is "root"
    When upstream server responds to "/headers" with status-code "200" and body "headers" with headers
      | header      | value |
      | x-my-header | yes   |
    And I request GET "/headers"
    Then content is "headers"
    Then header "x-my-header" is "yes"

  Scenario: Proxy request body
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
    And upstream server responds to "/" with status-code "200" and body "root"
    And I request POST "/" with body "request body"
    Then I should receive a response with status-code "200"
    And upstream request body was "request body"

  Scenario: Upstream health
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
        rescue:
          - catch: "exception:proxy-error:bad-gateway:no-healthy-upstreams"
            action: respond
            status-code: 502
            static-response: bad-gateway
upstreams:
  upstream:
    port: 11988
    health-checks:
      root:
        kind: liveness
        path: /health
        timeout: 1s
        period: 1s
        expected-status-code: 200
static-responses:
  bad-gateway:
    kind: raw
    status-code: 502
    body:
      - content-type: text/html
        content: Bad gateway
"""
    When upstream server responds to "/health" with status-code "500" and body "healthy"
    And upstream server responds to "/" with status-code "200" and body "root"
    And I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "502"
    When upstream server responds to "/health" with status-code "200" and body "root"
    And I wait for 4 seconds
    And I request GET "/"
    Then I should receive a response with status-code "200"
    When upstream server responds to "/health" with status-code "500" and body "root"
    And I wait for 4 seconds
    And I request GET "/"
    Then I should receive a response with status-code "502"

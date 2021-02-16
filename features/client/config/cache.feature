Feature: cache

  Scenario: Caching is disabled by default
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
        priority: 30
upstreams:
  upstream:
    port: 11988
"""
    When upstream server responds to "/" with status-code "200" and body "root" with headers
      | header        | value               |
      | cache-control | public, max-age=3 |
    And I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And header "x-exg-edge-cached" is not set

  Scenario: Caching is is not served after disabling it
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
        priority: 40
        cache:
          enabled: true
upstreams:
  upstream:
    port: 11988
"""
    When upstream server responds to "/" with status-code "200" and body "root" with headers
      | header        | value               |
      | cache-control | public, max-age=20 |
    And I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And header "x-exg-edge-cached" is not set
    When I wait for 1 seconds
    And I request GET "/"
    And header "x-exg-edge-cached" is "1"
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
        priority: 50
        cache:
          enabled: false
upstreams:
  upstream:
    port: 11988
"""
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And header "x-exg-edge-cached" is not set

  Scenario: Caching is working
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
        priority: 20
        cache:
          enabled: true
upstreams:
  upstream:
    port: 11988
"""
    When upstream server responds to "/" with status-code "200" and body "root" with headers
      | header        | value               |
      | cache-control | public, max-age=3 |
    And I spawn exogress client
    And I request GET "/"
    Then I should receive a response with status-code "200"
    And header "x-exg-edge-cached" is not set
    And I wait for 1 seconds
    And I request GET "/"
    And header "x-exg-edge-cached" is "1"
    And I wait for 3 seconds
    And I request GET "/"
    And header "x-exg-edge-cached" is not set

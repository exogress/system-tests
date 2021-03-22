Feature: post-processing image optimization

  Scenario: WebP optimization
    Given Exofile content
"""
---
version: 1.0.0
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
    And upstream server responds to "/file.jpg" with status-code "200" and body from file "assets/file.jpg" with headers
      | header       | value      |
      | content-type | image/jpeg |
    And upstream server responds to "/file.png" with status-code "200" and body from file "assets/file.png" with headers
      | header       | value     |
      | content-type | image/png |
    And I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"
    When I request GET "/file.png" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"

  Scenario: WebP optimization disable
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      proxy:
        kind: proxy
        upstream: upstream
        priority: 10
        post-processing:
          image:
            webp:
              enabled: false
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/file.jpg" with status-code "200" and body from file "assets/file.jpg" with headers
      | header       | value      |
      | content-type | image/jpeg |
    And upstream server responds to "/file.png" with status-code "200" and body from file "assets/file.png" with headers
      | header       | value     |
      | content-type | image/png |
    And I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/jpeg"
    When I request GET "/file.png" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/png"

  Scenario: WebP optimization disable for jpeg
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      proxy:
        kind: proxy
        upstream: upstream
        priority: 10
        post-processing:
          image:
            webp:
              enabled: true
              jpeg: false
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/file.jpg" with status-code "200" and body from file "assets/file.jpg" with headers
      | header       | value      |
      | content-type | image/jpeg |
    And upstream server responds to "/file.png" with status-code "200" and body from file "assets/file.png" with headers
      | header       | value     |
      | content-type | image/png |
    And I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/jpeg"
    When I request GET "/file.png" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"

  Scenario: WebP optimization disable for png
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      proxy:
        kind: proxy
        upstream: upstream
        priority: 10
        post-processing:
          image:
            webp:
              enabled: true
              png: false
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/file.jpg" with status-code "200" and body from file "assets/file.jpg" with headers
      | header       | value      |
      | content-type | image/jpeg |
    And upstream server responds to "/file.png" with status-code "200" and body from file "assets/file.png" with headers
      | header       | value     |
      | content-type | image/png |
    And I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"
    When I request GET "/file.png" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/png"

  Scenario: WebP optimization with cache enabled vary on accept header
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      proxy:
        kind: proxy
        upstream: upstream
        priority: 10
        cache:
          enabled: true
        post-processing:
          image:
            webp:
              enabled: true
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client
    And upstream server responds to "/file.jpg" with status-code "200" and body from file "assets/file.jpg" with headers
      | header        | value             |
      | content-type  | image/jpeg        |
      | cache-control | public, max-age=3 |
    And I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"
    And header "x-exg-edge-cached" is not set

    When I request GET "/file.jpg" with headers
      | header | value                |
      | accept | image/webp,*/*;q=0.8 |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/webp"
    And header "x-exg-edge-cached" is "1"

    When I request GET "/file.jpg" with headers
      | header | value |
      | accept | */*   |
    Then I should receive a response with status-code "200"
    And header "content-type" is "image/jpeg"
    And header "x-exg-edge-cached" is not set

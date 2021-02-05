Feature: post-processing image optimization
  Scenario: WebP optimization
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

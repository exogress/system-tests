Feature: post-processing encoding compression

  Scenario: Compression is not enabled for small body
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
    And upstream server responds to "/index.html" with status-code "200" and body "small" with headers
      | header       | value     |
      | content-type | text/html |
    And I request GET "/index.html" with headers
      | header          | value    |
      | accept-encoding | br, gzip |
    Then I should receive a response with status-code "200"
    And header "content-encoding" is not set

  Scenario: Compression is enabled by default for content-length > 100 bytes with priority to brotli
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
    And upstream server responds to "/index.html" with status-code "200" and body "=QWs4k8OcIuUNcxVFiWuY7UbI6/j/uaOcTvkwMMP6RZTsMeq6e17bhxIZZzF0VdZMXde26DdDVxJbRwhxvGNNvNQWs4k8OcIuUNcxVFiWuY7Ua" with headers
      | header       | value     |
      | content-type | text/html |
    And I request GET "/index.html" with headers
      | header          | value    |
      | accept-encoding | gzip, br |
    Then I should receive a response with status-code "200"
    And header "content-encoding" is "br"

  Scenario: Compression may be disabled
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
                post-processing:
                  encoding:
                    mime-types: "@compressible-mime-types"
                    brotli: false
                    gzip: true
        upstreams:
          upstream:
            port: 11988
        """
    When I spawn exogress client
    And upstream server responds to "/index.html" with status-code "200" and body "=QWs4k8OcIuUNcxVFiWuY7UbI6/j/uaOcTvkwMMP6RZTsMeq6e17bhxIZZzF0VdZMXde26DdDVxJbRwhxvGNNvNQWs4k8OcIuUNcxVFiWuY7Ua" with headers
      | header       | value     |
      | content-type | text/html |
    And I request GET "/index.html" with headers
      | header          | value    |
      | accept-encoding | br, gzip |
    Then I should receive a response with status-code "200"
    And header "content-encoding" is "gzip"

  Scenario: Compression alter min size and mime-types
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
                post-processing:
                  encoding:
                    mime-types: ["text/html"]
                    min_size: 10
        upstreams:
          upstream:
            port: 11988
        """
    When I spawn exogress client
    And upstream server responds to "/index.html" with status-code "200" and body "1234567890" with headers
      | header       | value     |
      | content-type | text/html |
    And I request GET "/index.html" with headers
      | header          | value    |
      | accept-encoding | br, gzip |
    Then I should receive a response with status-code "200"
    And header "content-encoding" is "br"

    When upstream server responds to "/index.html" with status-code "200" and body "1234567890" with headers
      | header       | value      |
      | content-type | text/plain |
    And I request GET "/index.html" with headers
      | header          | value    |
      | accept-encoding | br, gzip |
    Then I should receive a response with status-code "200"
    And header "content-encoding" is not set

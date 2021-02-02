Feature: request modification

  Scenario: Modify headers of requests
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
                kind: proxy
                upstream: upstream
                priority: 10
                rules:
                  - filter:
                      path: ["*"]
                    action:
                      modify-request:
                        headers:
                          insert:
                            "x-inserted": "yes"
                          append:
                            "x-sent-from-client2": "appended"
                          remove:
                            - "x-sent-from-client"
                      kind: invoke
        upstreams:
          upstream:
            port: 11988
        """
    When I spawn exogress client
    And upstream servers responds to "/" with status-code "200" and body "root"
    And I request GET "/" with headers
      | name               | value |
      | x-sent-from-client | true  |
      | x-sent-from-client2 | true  |
    Then upstream request header "x-sent-from-client" was not set
    And upstream request header "x-inserted" was "yes"
    And upstream request header "x-sent-from-client2" was "true,appended"
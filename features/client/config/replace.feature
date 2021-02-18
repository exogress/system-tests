Feature: replaces

  Scenario: Method matching
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      main:
        kind: proxy
        upstream: upstream
        priority: 10
        rules:
          - filter:
              path: ["query", "?", "end"]
            modify-request:
              path: ["r1", "a-{{ 1 }}"]
            action: invoke
          - filter:
              path: ["query", "?", "query"]
              query-params:
                "q1": "?"
            modify-request:
              path: ["b-{{ 1 }}-{{ q1 }}"]
            action: invoke
          - filter:
              path: ["query", "?", "with-path"]
              query-params:
                "q2": "*"
            modify-request:
              path: ["c", "{{ 1 }}", "{{ q2 }}"]
              trailing-slash: unset
              query-params:
                strategy: keep
                remove:
                  - q2
            action: invoke
          - filter:
              path: ["re", "/(.+)-(.+)/", ["23", "34"]]
              query-params:
                "q4": "/(a+)/"
            modify-request:
              path: ["{{ 1.2 }}-z", "{{ 2 }}-x", "y-{{ q4.0 }}"]
              trailing-slash: set
            action: invoke
          - filter:
              path: ["keep-query"]
              query-params:
                "q1": "?"
                "q2": "?"
                "q3": "3"
            modify-request:
              query-params:
                strategy: keep
                remove:
                  - q3
                set:
                  a1: "a"
            action: invoke
          - filter:
              path: ["remove-query"]
              query-params:
                "q1": "?"
                "q2": "?"
                "q3": "3"
            modify-request:
              query-params:
                strategy: remove
                keep:
                  - q1
                set:
                  b1: "b"
            action: invoke
      rebased:
        kind: proxy
        upstream: upstream
        priority: 20
        base-path: ["base", "path"]
        replace-base-path: ["replaced"]
        rules:
          - filter:
              path: ["p1", "p2", "?"]
              query-params:
                "qr1": "/a-(.+)-b/"
            modify-request:
              path: ["{{ 2 }}", "{{ qr1.1 }}"]
              query-params:
                strategy: keep
                remove:
                  - qr1
            action: invoke
upstreams:
  upstream:
    port: 11988
"""
    When I spawn exogress client

    And upstream server responds to "/r1/a-f" with status-code "200" and body "a2"
    And I request GET "/query/f/end"
    Then I should receive a response with status-code "200"
    And content is "a2"

    And upstream server responds to "/b-c-d/?q1=d" with status-code "200" and body "a3"
    And I request GET "/query/c/query/?q1=d"
    Then I should receive a response with status-code "200"
    And content is "a3"

    And upstream server responds to "/c/d/p1/p2/p3" with status-code "200" and body "a4"
    And I request GET "/query/d/with-path/?q2=p1/p2/p3"
    Then I should receive a response with status-code "200"
    And content is "a4"

    And upstream server responds to "/bb-z/34-x/y-aaaaaaaa/?q4=aaaaaaaa" with status-code "200" and body "a5"
    And I request GET "/re/aa-bb/34?q4=aaaaaaaa"
    Then I should receive a response with status-code "200"
    And content is "a5"

    And upstream server responds to "/replaced/asdf/34" with status-code "200" and body "a6"
    And I request GET "/base/path/p1/p2/asdf?qr1=a-34-b"
    Then I should receive a response with status-code "200"
    And content is "a6"

    And upstream server responds to "/keep-query?q1=1&q2=s&a1=a" with status-code "200" and body "a6"
    And I request GET "/keep-query?q1=1&q2=s&q3=3"
    Then I should receive a response with status-code "200"
    And content is "a6"

    And upstream server responds to "/remove-query?q1=1&b1=b" with status-code "200" and body "a6"
    And I request GET "/remove-query?q1=1&q2=s&q3=3"
    Then I should receive a response with status-code "200"
    And content is "a6"
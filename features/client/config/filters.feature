Feature: filters

  Scenario: Support filtering on invocation
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      next-handler:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["pass-through", "*"]
            action: respond
            static-response: fallback
          - filter:
              path: ["pref", "?"]
            action: respond
            static-response: fallback
          - filter:
              path: ["pref_with_many", "*"]
            action: respond
            static-response: fallback
          - filter:
              path: ["pref_with_many_and_post", "*", "end"]
            action: respond
            static-response: fallback
          - filter:
              path: ["*", "post"]
            action: respond
            static-response: fallback
          - filter:
              path: ["*"]
            action: next-handler
      dir:
        kind: static-dir
        dir: "./dir"
        priority: 10
        rules:
          - filter:
              path: ["*", "index1.html"]
            action: invoke
          - filter:
              path: ["?", "index2.html"]
            action: invoke
          - filter:
              path: ["*"]
            action: respond
            static-response: forbidden
        rescue:
          - catch: "status-code:404"
            action: respond
            static-response: not-found
    static-responses:
      fallback:
        kind: raw
        status-code: 200
        body:
          - content-type: text/html
            content: "<html>Fallback</html>"
      not-found:
        kind: raw
        status-code: 404
        body:
          - content-type: text/html
            content: "<html>Not found 404</html>"
      forbidden:
        kind: raw
        status-code: 403
        body:
          - content-type: text/html
            content: "<html>Forbidden 403</html>"
"""
    When I spawn exogress client
    And I create directories
      | dir     |
      | dir/a   |
      | dir/b/c |
      | dir/d   |

    And I create files with defined content
      | filename            | content |
      | dir/a/index2.html   | a2      |
      | dir/b/c/index1.html | bc1     |
      | dir/d/index1.html   | d1      |

    Then I'll get following responses
      | method | path                                      | body                       | status-code |
      | GET    | /a/index1.html                            | <html>Not found 404</html> | 404         |
      | GET    | /a/index2.html                            | a2                         | 200         |
      | GET    | /b/c/index1.html                          | bc1                        | 200         |
      | GET    | /b/c/index2.html                          | <html>Forbidden 403</html> | 403         |
      | GET    | /d/index1.html                            | d1                         | 200         |
      | GET    | /d/index2.html                            | <html>Not found 404</html> | 404         |
      | GET    | /index.html                               | <html>Forbidden 403</html> | 403         |
      | GET    | /pass-through/a                           | <html>Fallback</html>      | 200         |
      | GET    | /pref/a                                   | <html>Fallback</html>      | 200         |
      | GET    | /pref_with_many_and_post/a/b/c/sd/123/end | <html>Fallback</html>      | 200         |
      | GET    | /pref_with_many/a2/b2/c2/sd2/321          | <html>Fallback</html>      | 200         |
      | GET    | /f/bgf/csdf/daa/12e/post                  | <html>Fallback</html>      | 200         |

  Scenario: Trailing slash conditions
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      handle:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["trailing-require"]
              trailing-slash: require
            action: respond
            static-response: ok
          - filter:
              path: ["trailing-allow"]
              trailing-slash: allow
            action: respond
            static-response: ok
          - filter:
              path: ["trailing-deny"]
              trailing-slash: deny
            action: respond
            static-response: ok
      last-one:
        kind: pass-through
        priority: 1000
        rules:
          - filter:
              path: ["*"]
            action: respond
            static-response: not-found
    static-responses:
      ok:
        kind: raw
        status-code: 200
        body:
          - content-type: text/plain
            content: "OK"
      not-found:
        kind: raw
        status-code: 404
        body:
          - content-type: text/plain
            content: "NOT FOUND"
"""
    When I spawn exogress client
    Then I'll get following responses
      | method | path               | body      | status-code |
      | GET    | /trailing-allow    | OK        | 200         |
      | GET    | /trailing-allow/   | OK        | 200         |
      | GET    | /trailing-require  | NOT FOUND | 404         |
      | GET    | /trailing-require/ | OK        | 200         |
      | GET    | /trailing-deny     | OK        | 200         |
      | GET    | /trailing-deny/    | NOT FOUND | 404         |

  Scenario: Method matching
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      handle:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["post-or-put"]
              methods:
                - POST
                - PUT
            action: respond
            static-response: ok
      last-one:
        kind: pass-through
        priority: 1000
        rules:
          - filter:
              path: ["*"]
            action: respond
            static-response: not-found
    static-responses:
      ok:
        kind: raw
        status-code: 200
        body:
          - content-type: text/plain
            content: "OK"
      not-found:
        kind: raw
        status-code: 404
        body:
          - content-type: text/plain
            content: "NOT FOUND"
"""
    When I spawn exogress client
    Then I'll get following responses
      | method | path         | body      | status-code |
      | POST   | /post-or-put | OK        | 200         |
      | PUT    | /post-or-put | OK        | 200         |
      | GET    | /post-or-put | NOT FOUND | 404         |
      | DELETE | /post-or-put | NOT FOUND | 404         |

  Scenario: Query matching
    Given Exofile content
"""
---
version: 1.0.0-pre.1
revision: 1
name: static-dir
mount-points:
  default:
    handlers:
      handle:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["query"]
              query:
                action: "?"
                path: "*"
                exact: val
                maybe: ~
                empty: ""
                oneof: ["1", "2", "3"]
            action: respond
            static-response: ok
      last-one:
        kind: pass-through
        priority: 1000
        rules:
          - filter:
              path: ["*"]
            action: respond
            static-response: not-found
    static-responses:
      ok:
        kind: raw
        status-code: 200
        body:
          - content-type: text/plain
            content: "OK"
      not-found:
        kind: raw
        status-code: 404
        body:
          - content-type: text/plain
            content: "NOT FOUND"
"""
    When I spawn exogress client
    Then I'll get following responses
      | method | path                                                            | body      | status-code |
      | GET    | /query?action=do&path=a/b&exact=val&empty=&oneof=1              | OK        | 200         |
      | GET    | /query?action=do&path=a/b&exact=val&empty=&oneof=2              | OK        | 200         |
      | GET    | /query?action=do&path=a&exact=val&empty=&oneof=3                | OK        | 200         |
      | GET    | /query?action=other&path=a/b&exact=val&maybe=123&empty=&oneof=1 | OK        | 200         |
      | GET    | /query?action=other&path=a/b&exact=val&maybe=123&empty=&oneof=4 | NOT FOUND | 404         |
      | GET    | /query?action=do&path=&exact=val&empty=&oneof=2                 | NOT FOUND | 404         |
      | GET    | /query?action=other&path=a/b&exact=val1&empty=&oneof=3          | NOT FOUND | 404         |
      | GET    | /query?action=&path=a/b&exact=val1&empty=&oneof=1               | NOT FOUND | 404         |
      | GET    | /query?action=do&path=a/b&exact=val&oneof=2                     | NOT FOUND | 404         |

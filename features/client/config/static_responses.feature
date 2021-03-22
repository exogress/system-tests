Feature: static response

  Scenario: respond with static-response embedded and referenced
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      resp:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["static", "embedded", "plain"]
            action: respond
            static-response:
              kind: raw
              status-code: 201
              body:
                - content-type: text/plain
                  content: "plain simple"
          - filter:
              path: ["static", "referenced", "handler"]
            action: respond
            static-response: handler
          - filter:
              path: ["static", "referenced", "config"]
            action: respond
            static-response: config
          - filter:
              path: ["static", "referenced", "mount-point"]
            action: respond
            static-response: mount
        static-responses:
          handler:
              kind: raw
              status-code: 200
              body:
                - content-type: text/plain
                  content: "referenced handler"
    static-responses:
      mount:
          kind: raw
          status-code: 200
          body:
            - content-type: text/plain
              content: "mount-point"
static-responses:
  config:
      kind: raw
      status-code: 200
      body:
        - content-type: text/plain
          content: "config"
"""
    When I spawn exogress client
    And I request GET "/static/embedded/plain"
    Then I should receive a response with status-code "201"
    And content is "plain simple"

    And I request GET "/static/referenced/handler"
    Then I should receive a response with status-code "200"
    And content is "referenced handler"

    And I request GET "/static/referenced/config"
    Then I should receive a response with status-code "200"
    And content is "config"

    And I request GET "/static/referenced/mount-point"
    Then I should receive a response with status-code "200"
    And content is "mount-point"

  Scenario: handlebars engine
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      resp:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["resp", "*"]
              query-params:
                q1: "?"
            action: respond
            data:
              v1: value1
            static-response:
              kind: raw
              status-code: 201
              body:
                - content-type: text/plain
                  content: "domain = {{ this.facts.mount_point_hostname }}; {{ this.data.v1 }}; {{ this.matches.q1 }}; {{ this.matches.1 }}"
                  engine: handlebars
"""
    When I spawn exogress client
    And I request GET "/resp?q1=1"
    Then I should receive a response with status-code "201"
    And content is "domain = system-tests.glebpom.lexg.link; value1; 1; "

    And I request GET "/resp/a/b/c?q1=asd"
    Then I should receive a response with status-code "201"
    And content is "domain = system-tests.glebpom.lexg.link; value1; asd; [a, b, c, ]"

  Scenario: respond with static-response as exception handling
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    rescue:
      - catch: "status-code:404"
        action: respond
        static-response:
          kind: raw
          status-code: 200
          body:
            - content-type: text/plain
              content: "404 caught"
    handlers:
      static:
        kind: static-dir
        dir: ./not-existing
        priority: 5
        rules:
          - filter:
              path: ["respond-than-catch"]
            action: invoke
      resp:
        kind: proxy
        upstream: upstream
        priority: 10
        rules:
          - filter:
              path: ["throw"]
            action: throw
            exception: my-exception
          - filter:
              path: ["mp"]
            action: invoke
          - filter:
              path: ["rule-ref"]
            action: invoke
            rescue:
              - catch: "exception:proxy-error"
                action: respond
                static-response: rule-reference
          - filter:
              path: ["rule"]
            action: invoke
            rescue:
              - catch: "exception:proxy-error"
                action: respond
                static-response:
                  kind: raw
                  status-code: 503
                  body:
                    - content-type: text/plain
                      content: "error caught in rule"
        rescue:
          - catch: "exception:proxy-error"
            action: respond
            static-response:
              kind: raw
              status-code: 503
              body:
                - content-type: text/plain
                  content: "error caught"
          - catch: "exception:my-exception"
            action: respond
            static-response: exception-occurred
static-responses:
  rule-reference:
    kind: raw
    status-code: 503
    body:
      - content-type: text/plain
        content: "error caught in rule with referenced resp"
  exception-occurred:
    kind: raw
    status-code: 500
    body:
      - content-type: text/plain
        content: "exception thrown"

upstreams:
  upstream:
    port: 23673
"""
    When I spawn exogress client
    And I request GET "/mp"
    Then I should receive a response with status-code "503"
    And content is "error caught"

    And I request GET "/rule"
    Then I should receive a response with status-code "503"
    And content is "error caught in rule"

    And I request GET "/rule-ref"
    Then I should receive a response with status-code "503"
    And content is "error caught in rule with referenced resp"

    And I request GET "/throw"
    Then I should receive a response with status-code "500"
    And content is "exception thrown"

    And I request GET "/respond-than-catch"
    Then I should receive a response with status-code "200"
    And content is "404 caught"

  Scenario: exception during exception handling
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      static:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["throw"]
            action: throw
            exception: my-exception
        rescue:
          - catch: "exception:my-exception"
            action: respond
            static-response:
              kind: raw
              status-code: 500
              body:
                - content-type: text/plain
                  content: "{{"
                  engine: handlebars
    rescue:
      - catch: "exception:static-response-error"
        action: respond
        static-response:
          kind: raw
          status-code: 400
          body:
            - content-type: text/plain
              content: "Exception in rescue"

"""
    When I spawn exogress client
    And I request GET "/throw"
    Then I should receive a response with status-code "400"
    And content is "Exception in rescue"

  Scenario: static response is not defined
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      handler:
        kind: pass-through
        priority: 10
        rules:
          - filter:
              path: ["throw"]
            action: respond
            static-response: not-existing
          - filter:
              path: ["throw-catch-in-rule"]
            action: respond
            static-response: not-existing
            rescue:
              - catch: "exception:static-response-error"
                action: respond
                static-response:
                  kind: raw
                  status-code: 404
                  body:
                    - content-type: text/plain
                      content: "static resp error in rule"
    rescue:
      - catch: "exception:static-response-error"
        action: respond
        static-response:
          kind: raw
          status-code: 404
          body:
            - content-type: text/plain
              content: "static resp error"
"""
    When I spawn exogress client

    And I request GET "/throw"
    Then I should receive a response with status-code "404"
    And content is "static resp error"

    And I request GET "/throw-catch-in-rule"
    Then I should receive a response with status-code "404"
    And content is "static resp error in rule"

  Scenario: static response by catching status-code
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    rescue:
      - catch: "status-code:404"
        action: respond
        static-response:
          kind: raw
          status-code: 404
          body:
            - content-type: text/plain
              content: "not found"
    handlers:
      static:
        kind: static-dir
        dir: ./not-existing
        priority: 5
"""
    When I spawn exogress client

    And I request GET "/throw"
    Then I should receive a response with status-code "404"
    And content is "not found"

  Scenario: static response rescue sequentially
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      static:
        kind: static-dir
        dir: ./not-existing
        priority: 5
        rules:
          - filter:
              path: ["*"]
            action: respond
            static-response: resp
        static-responses:
          resp:
            kind: raw
            status-code: 200
            body:
              - content-type: text/plain
                content: "response"
"""
    When I spawn exogress client

    And I request GET "/"
    Then I should receive a response with status-code "200"
    And content is "response"

  Scenario: simple static resp exception handling
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      static:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["a"]
            action: respond
            static-response:
              kind: raw
              status-code: 500
              body:
                - content-type: text/plain
                  content: "{{"
                  engine: handlebars
rescue:
  - catch: "exception:static-response-error"
    action: respond
    static-response:
      kind: raw
      status-code: 400
      body:
        - content-type: text/plain
          content: "exception"
"""
    When I spawn exogress client
    And I request GET "/a"
    Then I should receive a response with status-code "400"
    And content is "exception"

  Scenario: data-merge and re-throw
    Given Exofile content
"""
---
version: 1.0.0
revision: 1
name: proxy
mount-points:
  default:
    handlers:
      pass-through:
        kind: pass-through
        priority: 5
        rules:
          - filter:
              path: ["a"]
            action: throw
            data:
              step1: yes
              last_step: step1
            exception: throw-with-data
      static:
        kind: static-dir
        dir: ./non-existing
        priority: 10
        rescue:
          - catch: "status-code:404"
            action: throw
            data:
              step2: yes
              last_step: step2
            exception: throw-with-data
    rescue:
      - catch: "exception:throw-with-data"
        action: respond
        data:
          step3: yes
          last_step: step3
        static-response:
          kind: raw
          status-code: 200
          body:
            - content-type: text/plain
              content: "last = {{ this.data.last_step }}. step1 = {{ this.data.step1 }}, step2 = {{ this.data.step2 }}, step3 = {{ this.data.step3 }}"
              engine: handlebars
"""
    When I spawn exogress client

    And I request GET "/a"
    Then I should receive a response with status-code "200"
    And content is "last = step3. step1 = yes, step2 = , step3 = yes"

    And I request GET "/b"
    Then I should receive a response with status-code "200"
    And content is "last = step3. step1 = , step2 = yes, step3 = yes"

#  TODO: data merging
#  TODO: tests on proper scope in regard to data merging in case of exception -> static-resp -> exception
#  TODO: scope.prev may be ann error, since we have to rely on scope which was connected

#  action: throw
#  action: respond
#  catch: throw
#  catch: respond

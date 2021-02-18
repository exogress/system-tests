#Feature: application firewall
#
#  Scenario: Filter out SQLi and XSS
#    Given Exofile content
#"""
#---
#version: 1.0.0-pre.1
#revision: 1
#name: proxy
#mount-points:
#  default:
#    handlers:
#      protect:
#        kind: application-firewall
#        uri-xss: true
#        uri-sqli: true
#        priority: 10
#        rescue:
#          - catch: "exception:application-firewall-error:injection-detected"
#            action: respond
#            static-response: injection
#            status-code: 403
#static-responses:
#  injection:
#    kind: raw
#    body:
#      - content-type: text/plain
#        content: "{{ this.data.detected }}"
#        engine: handlebars
#"""
#    When I spawn exogress client
#    And I request GET "/?r=%3Cscript%20type%3D%27text%2Fjavascript%27%3Ealert%28%27xss%27%29%3B%3C%2Fscript%3E"
#    Then I should receive a response with status-code "403"
#    And content is "libinjection:xss"
#    And I request GET "/?r=-1%27%20and%201%3D1%20union%2F%2A%20foo%20%2A%2Fselect%20load_file%28%27%2Fetc%2Fpasswd%27%29--"
#    Then I should receive a response with status-code "403"
#    And content is "libinjection:sqli:s&amp;1UE"

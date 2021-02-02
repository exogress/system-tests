And(/^upstream servers responds to "([^"]*)" with status\-code "([^"]*)" and body "([^"]*)"$/) do |path, status_code, body|
  $active_stub_path = path
  WebServer.add_rule(path, status_code, body, {})
end

And(/^responds with header "([^"]*)" equals to "([^"]*)"$/) do |name, value|
  WebServer.add_header_to_rule($active_stub_path, name, value)
end
And(/^upstream servers responds to "([^"]*)" with status\-code "([^"]*)" and body "([^"]*)"$/) do |path, status_code, body|
  $active_stub_path = path
  WebServer.add_rule(path, status_code, body, {})
end

And(/^responds with header "([^"]*)" equals to "([^"]*)"$/) do |name, value|
  WebServer.add_header_to_rule($active_stub_path, name, value)
end

Then(/^upstream request header "([^"]*)" was not set$/) do |header|
  req = WebServer.last_request
  expect(req.header[header]).to be_empty
end

And(/^upstream request header "([^"]*)" was "([^"]*)"$/) do |header, value|
  req = WebServer.last_request
  expect(req.header[header].to_set).to eq(value.split(",").to_set)
end
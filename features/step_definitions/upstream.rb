And(/^upstream server responds to "([^"]*)" with status\-code "([^"]*)" and body "([^"]*)" with headers$/) do |path, status_code, body, table|
  $active_stub_path = path
  headers = {}
  table.hashes.each do |item|
    name = item[:header]
    value = item[:value]
    headers[name] = value
  end
  WebServer.add_rule(path, status_code, body, headers)
end

And(/^upstream server responds to "([^"]*)" with status\-code "([^"]*)" and body "([^"]*)"$/) do |path, status_code, body|
  $active_stub_path = path
  WebServer.add_rule(path, status_code, body, {})
end

Then(/^upstream request body was "([^"]*)"$/) do |request_body|
  req_body = WebServer.last_request_body
  expect(req_body).to eq(request_body)
end

Then(/^upstream request header "([^"]*)" was not set$/) do |header|
  req = WebServer.last_request
  expect(req.header[header]).to be_empty
end

And(/^upstream request header "([^"]*)" was "([^"]*)"$/) do |header, value|
  req = WebServer.last_request
  expect(req.header[header].to_set).to eq(value.split("|").to_set)
end

And(/^upstream server responds to "([^"]*)" with status\-code "([^"]*)" and body from file "([^"]*)" with headers$/) do |path, status_code, file_path, table|
  $active_stub_path = path
  headers = {}
  table.hashes.each do |item|
    name = item[:header]
    value = item[:value]
    headers[name] = value
  end
  WebServer.add_file_rule(path, status_code, file_path, headers)
end
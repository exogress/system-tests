require 'net/http'

And(/^I request GET "([^"]*)"$/) do |path|
  uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
  $last_http_response = Net::HTTP.get_response(uri)
end

Then(/^I should receive a response with status\-code "([^"]*)"$/) do |status_code|
  expect($last_http_response.code).to eq(status_code)
end

And(/^content is "([^"]*)"$/) do |expected_content|
  expect($last_http_response.body).to eq(expected_content)
end

Then(/^header "([^"]*)" is "([^"]*)"$/) do |name, value|
  expect($last_http_response.header[name]).to eq(value)
end

Then(/^I'll get following responses$/) do |table|
  table.hashes.each do |item|
    method = item[:method]
    path = item[:path]
    body = item[:body]
    status_code = item["status-code"]

    uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
    resp = Net::HTTP.get_response(uri)

    expect(resp.code).to eq(status_code)
    expect(resp.body).to eq(body)
  end
end

And(/^I request GET "([^"]*)" with headers$/) do |path, table|
  uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
  headers = {}
  table.hashes.each do |item|
    name = item[:name]
    value = item[:value]
    headers[name] = value
  end
  $last_http_response = Net::HTTP.get_response(uri, headers)
end
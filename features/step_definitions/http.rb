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
  Kernel.puts $last_http_response.header[name]
  expect($last_http_response.header[name]).to eq(value)
end
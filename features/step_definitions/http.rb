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

Then(/^header "([^"]*)" is not set$/) do |name|
  expect($last_http_response.header[name]).to be_nil
end

Then(/^I'll get following responses$/) do |table|
  table.hashes.each do |item|
    method = item[:method]
    path = item[:path]
    body = item[:body]
    status_code = item["status-code"]

    uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
    resp = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      request = if method == "GET"
        Net::HTTP::Get.new uri
      elsif method == "POST"
        Net::HTTP::Post.new uri
      elsif method == "PUT"
        Net::HTTP::Put.new uri
      elsif method == "DELETE"
        Net::HTTP::Delete.new uri
      elsif method == "HEAD"
        Net::HTTP::Head.new uri
      elsif method == "PATCH"
        Net::HTTP::Patch.new uri
      end

      http.request request
    end

    expect(resp.code).to eq(status_code)
    expect(resp.body).to eq(body)

    $last_http_response = resp
  end
end

And(/^I request GET "([^"]*)" with headers$/) do |path, table|
  uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
  headers = {}
  table.hashes.each do |item|
    name = item[:header]
    value = item[:value]
    headers[name] = value
  end
  $last_http_response = Net::HTTP.get_response(uri, headers)
end

And(/^I request POST "([^"]*)" with body "([^"]*)"$/) do |path, request_body|
  uri = URI.parse("https://#{ENV["DOMAIN"]}#{path}")
  resp = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
    request = Net::HTTP::Post.new uri
    request.body = request_body
    http.request request
  end

  $last_http_response = resp

end
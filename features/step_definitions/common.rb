And(/^I wait for (\d+) seconds$/) do |arg|
  sleep(arg.to_f)
end

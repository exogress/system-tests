require 'fileutils'

When(/^I create directory "([^"]*)"$/) do |dir|
  FileUtils.mkdir_p $scenario_dir + "/" + dir
end

And(/^create file "([^"]*)" with content "([^"]*)"$/) do |file, content|
  File.write($scenario_dir + "/" + file, content)
end

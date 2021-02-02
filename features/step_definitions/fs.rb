require 'fileutils'

When(/^I create directory "([^"]*)"$/) do |dir|
  FileUtils.mkdir_p $scenario_dir + "/" + dir
end

And(/^I create file "([^"]*)" with content "([^"]*)"$/) do |file, content|
  File.write($scenario_dir + "/" + file, content)
end

When(/^I create directories$/) do |table|
  # table is a table.hashes.keys # => [:dir/a]
  table.hashes.each do |item|
    dir = item[:dir]
    FileUtils.mkdir_p $scenario_dir + "/" + dir
  end
end

And(/^I create files with defined content$/) do |table|
  table.hashes.each do |item|
    file = item[:filename]
    content = item[:content]
    File.write($scenario_dir + "/" + file, content)
  end
end
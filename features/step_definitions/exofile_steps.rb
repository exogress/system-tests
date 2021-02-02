Given(/^Exofile content$/) do |text|
  File.write($scenario_dir + "/Exofile", text)
  sleep(2.0)
end
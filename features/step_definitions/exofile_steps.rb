Given(/^Exofile content$/) do |text|
  File.write($scenario_dir + "/Exofile.yml", text)
  sleep(2.0)
end
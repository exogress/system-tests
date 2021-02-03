require 'open3'
require 'rspec/expectations'

class ExogressCli
  include RSpec::Matchers
  extend RSpec::Matchers

  @@process_lock = Mutex::new
  @@pid = nil

  def self.stop
    @@process_lock.synchronize do
      Process.kill("KILL", @@pid)
    end
  end

  def self.spawn_cli(app_args)
    mutex = Mutex.new
    spawned = ConditionVariable.new

    Thread.new do
      cmd = ENV["COMMAND"] || "exogress"
      env = {}

      if ENV["CLOUD_ENDPOINT"]
        env["CLOUD_ENDPOINT"] = ENV["CLOUD_ENDPOINT"]
      end

      $exogress_cli_stdin, $exogress_cli_stdout, $exogress_cli_stderr, $exogress_cli_wait_thr =
        Open3.popen3(env, "#{cmd} spawn #{app_args}", :chdir => $scenario_dir)

      @@process_lock.synchronize do
        @@pid = $exogress_cli_wait_thr[:pid]
      end

      Thread.new do
        while line = $exogress_cli_stdout.gets do
          if line.include? "to signal server established"
            mutex.synchronize do
              spawned.signal
            end
          end
          if line.include? "ERROR"
            STDERR.puts(line)
          else
            if ENV["LOG_CLIENT"] == "1"
              STDERR.puts(line)
            end
          end
        end
      end
      Thread.new do
        while line = $exogress_cli_stderr.gets do
          STDERR.puts(line)
        end
      end
    end

    mutex.synchronize do
      expect { spawned.wait(mutex) }.to_not raise_error, "client stopped before getting initialized"
    end
  end
end

When(/^I spawn exogress client$/) do
  ExogressCli::spawn_cli("")
end

When(/^I spawn exogress client with profile "([^"]*)"$/) do |profile|
  ExogressCli::spawn_cli("--profile=#{profile}")
end

When(/^I stop running exogress client$/) do
  ExogressCli::stop
end
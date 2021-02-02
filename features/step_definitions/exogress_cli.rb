require 'open3'

When(/^I spawn exogress client$/) do
  mutex = Mutex.new
  spawned = ConditionVariable.new

  Thread.new do
      cmd = ENV["COMMAND"] || "exogress"
      env = {}

      if ENV["CLOUD_ENDPOINT"]
        env["CLOUD_ENDPOINT"] = ENV["CLOUD_ENDPOINT"]
      end

      $exogress_cli_stdin, $exogress_cli_stdout, $exogress_cli_stderr, $exogress_cli_wait_thr =
        Open3.popen3(env, "#{cmd} spawn", :chdir => $scenario_dir)
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

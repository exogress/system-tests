require 'open3'

When(/^I spawn exogress client$/) do
  mutex = Mutex.new
  spawned = ConditionVariable.new

  Thread.new do
      $exogress_cli_stdin, $exogress_cli_stdout, $exogress_cli_stderr, $exogress_cli_wait_thr = Open3.popen3("exogress spawn", :chdir => $scenario_dir)
      Thread.new do
        while line = $exogress_cli_stdout.gets do
          if line.include? "to signal server established"
            mutex.synchronize do
              spawned.signal
            end
          end
          if line.include? "ERROR"
            Kernel.puts(line)
          else
            if ENV["LOG_CLIENT"] == "1"
              Kernel.puts(line)
            end
          end
        end
      end
      Thread.new do
        while line = $exogress_cli_stderr.gets do
          Kernel.puts(line)
        end
      end
  end

  mutex.synchronize do
    expect { spawned.wait(mutex) }.to_not raise_error, "client stopped before getting initialized"
  end
end

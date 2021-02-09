require 'tmpdir'
require 'webrick'

class WebServer
  @@lock = Mutex::new
  @@rules = {}
  @@last_request = nil
  @@last_request_body = nil

  def self.reset_rules
    @@lock.synchronize do
      @@rules = {}
      @@last_request = {}
      @@last_request_body = {}
    end
  end

  def self.last_request
    @@lock.synchronize do
      @@last_request
    end
  end

  def self.last_request_body
    @@lock.synchronize do
      @@last_request_body
    end
  end

  def self.add_rule(path, status_code, body, headers)
    @@lock.synchronize do
      @@rules[path] = { status_code: status_code, body: body, headers: headers }
    end
  end

  def self.add_file_rule(path, status_code, file_path, headers)
    @@lock.synchronize do
      @@rules[path] = { status_code: status_code, body: File.read(file_path), headers: headers }
    end
  end

  # def self.add_header_to_rule(path, header_name, header_value)
  #   @@lock.synchronize do
  #     @@rules[path][:headers][header_name] = header_value
  #   end
  # end

  def self.spawn_bg
    Thread.new {
      server = WEBrick::HTTPServer.new :Port => 11988
      server.mount_proc '/' do |req, res|
        @@lock.synchronize do
          @@last_request_body = req.body
          @@last_request = req

          path = req.path
          if req.query_string and !req.query_string.empty?
            path = path + "?" + req.query_string
          end
          by_path = @@rules[path]

          if by_path
            res.body = by_path[:body]
            by_path[:headers].each do |name, value|
              res.header[name] = value
            end
            res.status = by_path[:status_code]
          else
            res.body = "Not Found"
            res.status = 404
          end
        end
      end
      server.start
    }
  end
end

WebServer.spawn_bg


Before do |scenario|
  $scenario_dir = Dir.mktmpdir
end

After do |scenario|
  kill_running_client
  delete_scenario_dir
  WebServer.reset_rules

  $active_stub_path = nil
  $exogress_cli_stdin = nil
  $exogress_cli_stdout = nil
  $exogress_cli_stderr = nil
  $exogress_cli_wait_thr = nil
  $scenario_dir = nil
end

def kill_running_client
  if $exogress_cli_wait_thr
    Cucumber.logger.debug("killing running exogress client")
    begin
      Process.kill('KILL', $exogress_cli_wait_thr.pid)
    rescue Errno::ESRCH
    end
  end
end

def delete_scenario_dir
  if $scenario_dir
    begin
      FileUtils.rm_r $scenario_dir, force: true
    rescue Errno::ENOTEMPTY
    end
  end
end

at_exit do
  kill_running_client
  delete_scenario_dir
end

#!/usr/bin/env ruby

require 'json'
require 'parallel'
require 'open3'
require 'optparse'
require 'ostruct'

options = OpenStruct.new
options.url_file = "url.json"
options.log_header = "log"
options.timeout_period = 20
options.threads = 4
options.cookie = nil
options.user_agent = nil
options.auth_info = nil

# parse options

OptionParser.new do |opts|
  opts.banner =  "Usage: #{__FILE__} [options]"

  opts.on("-f URLFILE", "--urlfile URLFILE", String, "Test for URLs in URLFILE.", "Defaults to \"url.json\".") do |u|
    options.url_file = u
  end

  opts.on("-l LOG_HEADER", "--log-header LOG_HEADER", String, "Outputs log in [LOG_HEADER]_[datetime].log.json.", "Defaults to \"log\".") do |lh|
    options.log_header = lh
  end

  opts.on("-t TO", "--timeout TO", Integer, "Timeout in TO seconds. Defaults to 20.") do |to|
    options.timeout_period = to
  end

  opts.on("-p PT", "--parallel-threads PT", Integer, "Run in PT parallel threads. Defaults to 4.") do |t|
    options.threads = t
  end

  opts.on("-b COOKIE", "--cookie COOKIE", String, "Cookie values to be used in HTTP request. Same as curl's -b option. Defaults to blank.") do |c|
    options.cookie = c
  end

  opts.on("-A AGENT", "--user-agent AGENT", String, "Use User-Agent value AGENT. Same as curl's -A option. Defaults to blank.") do |ua|
    options.user_agent = ua
  end

  opts.on("-u AUTH_INFO", "--basic-auth AUTH_INFO", String, "Basic Authentication info, in user:password format. Same as curl's -u option. Defaults to blank.") do |ai|
    options.auth_info = ai
  end
end.parse!

# create log file name
log_file = "logs/" + options.log_header + "_" + Time.now.strftime("%Y%m%d%H%M%S") + ".log.json"

urls = JSON.load(File.read(options.url_file))

results = Parallel.map(urls, :in_threads => options.threads) do |target|
  name = target["name"]
  url  = target["url"]
  result = nil
  th_value = nil
  # uses Open3 to open external curl process.
  curl_options = []
  if !options.cookie.nil?
    curl_options.push '-b "' + options.cookie + '"'
  end
  if !options.user_agent.nil?
    curl_options.push '-A "' + options.user_agent + '"'
  end
  if !options.auth_info.nil?
    curl_options.push '-u ' + options.auth_info
  end
  curl_options_string = curl_options.join(' ')
  Open3.popen2e("curl -s -o /dev/null #{curl_options_string} -w \"%{http_code} %{time_total}\" \"#{url}\" --globoff") { |stdin, stdouterr, wait_thr|
    th = Thread.new { stdouterr.read }
    if !wait_thr.join(options.timeout_period)
      puts "*warn* Execution terminated: \"#{name}\""
      begin
        Process.kill(:TERM, wait_thr.pid)
      rescue Errno::ESRCH
        puts "*warn* pid for #{name} does not exist"
      end
      result = {"status" => "timed_out", "time" => -1}
    else
      th_value = th.value
      result_array = th_value.chomp.split(" ")
      result = {"status" => result_array[0].to_i, "time" => (result_array[1].to_f * 1000).to_i}
    end
  }
  result["name"] = name
  result["url"]  = url
  result
end

puts "#{urls.length} pages loaded!"
puts "writing logs to #{log_file} ..."

f = open(log_file,"w")
f.puts(JSON.pretty_generate(results))
f.close

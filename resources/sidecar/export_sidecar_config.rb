#!/usr/bin/env ruby
# Encoding: utf-8
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


$stdout.sync = true
$stderr.sync = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

puts('STARTING EXPORT_SIDECAR_CONFIG')

require 'net/http'
require 'json'

port = ENV['SIDECAR_PROXY_PORT'] || 8087

retries = 36
response = nil
url = "http://127.0.0.1:#{port}/sidecar"
uri = URI(url)
puts("CALLING: #{url}")
begin
  response = Net::HTTP.get(uri)
  #puts("GOT RESPONSE: #{response}")
rescue Exception
  print("EXCEPTION: #{$!}")
  sleep 5
  retry if (retries -= 1) > 0
end

#puts("RESPONSE: #{response}")

def envify(s)
  return s.upcase.gsub(".", "_").gsub("-", "_").gsub("[", "_").gsub("]", "")
end

if response
  resp_obj = JSON.parse(response)
  open('./sidecar_export.sh', 'w') {
    |f|
    #f.puts("#!/usr/bin/env bash\n")
    resp_obj.each{ |k,v|
      if k =~ /^[A-Za-z0-9\.\_\-\[\]]*$/
        f.puts("export #{envify(k)}=\"#{v}\"\n")
      else
        puts("invalid key: #{k}")
      end
    }
  }
  File.chmod(0744, "./sidecar_export.sh")
else
  exit(255)
end




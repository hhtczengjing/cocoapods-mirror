require 'uri'
require 'fileutils'
require 'multi_json'
require 'cocoapods'
require 'net/ssh'

$current_dir = File.dirname(File.expand_path(__FILE__))
Dir[File.join($current_dir, "*.rb")].each do |file|
  require_relative(file)
end

desc '镜像一个 github 包至 gitlab 仓库 rake "clone[AFNetworking]"'
task :clone, [:name] do |t, p| 
  name = p[:name]
  Powerdata::Podspec.new(name).parse()
end

desc 'gitlab 服务器镜像 Cocoapod Spec'
task :mirror, [:repo] do |t, p|
  host        = 'YOUR_SERVER_HOST'
  user        = 'YOUR_SERVER_USERNAME'
  options     = {:password => 'YOUR_SERVER_PASSWORD'}
  puts "Connect gitlab server and mirror"
  Net::SSH.start(host, user, options) do |ssh|
    gitmirror_path = 'YOUR_SERVER_GITMIRROR_PATH'
    cmd = "sudo -u gitmirror -H rake \"add[\"#{p[:repo]}\"]\""
    stdout = ssh.exec!("cd #{gitmirror_path} && rake add[\"#{p[:repo]}\"]")
    puts stdout
    ssh.loop
  end
end
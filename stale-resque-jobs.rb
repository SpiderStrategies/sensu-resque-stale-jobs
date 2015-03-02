#!/usr/bin/env ruby
#
# A sensu plugin to determine if there are jobs sitting in the timestamps set too long
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'redis'

class RedisChecks < Sensu::Plugin::Check::CLI

  option :host,
    :short => "-h HOST",
    :long => "--host HOST",
    :description => "Redis hostname",
    :required => true

  option :port,
    :short => "-p PORT",
    :long => "--port PORT",
    :description => "Redis port",
    :default => "6379"

  option :password,
    :short => "-P PASSWORD",
    :long => "--password PASSWORD",
    :description => "Redis Password to connect with"

  option :namespace,
    :description => "Resque namespace",
    :short => "-n NAMESPACE",
    :long => "--namespace NAMESPACE",
    :default => "resque"

  option :warn,
    :short => "-w MINUTES",
    :long => "--warn MINUTES",
    :description => "Warn when timestamp has been stale so many minutes",
    :proc => proc {|p| p.to_i },
    :required => true

  option :crit,
    :short => "-c MINUTES",
    :long => "--crit MINUTES",
    :description => "Critical when timestamp has been stale for so many minutes",
    :proc => proc {|p| p.to_i },
    :required => true

  def run
    redis = Redis.new(:host => config[:host], :port => config[:port], :password => config[:password])

    staleCrit = Time.now - config[:crit] * 60
    staleWarn = Time.now - config[:warn] * 60

    redis.keys(config[:namespace] + ':timestamps:*').each do |key|
      # puts key, redis.smembers(key)
      #TODO This is expensive for lots of timestamps
      redis.smembers(key).each do |timestamp|
        t = Time.at(timestamp.split(':')[2].to_i)
        if (t < staleCrit)
          critical "CRITICAL: Resque queue timestamp #{key}, has a timestamp of #{t}!"
        elsif (t < staleCrit)
          warning "WARNING: Resque queue timestamp #{key}, has a timestamp of #{t}!"
        end
      end
    end
    ok "No stale timestamps"
  end
end

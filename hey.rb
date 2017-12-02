#!/usr/bin/env ruby
# A Ruby script for tracking interruptions
# Author: Rusty Gerard (https://github.com/R-Gerard/)

require 'open3'

def usage()
  STDERR.puts 'Usage:'
  STDERR.puts 'Create an event:        hey <name> [optional reason string]'
  STDERR.puts 'List all events:        hey list'
  STDERR.puts 'Adding/revising reason: hey reason <event_id> [optional reason string]'
  STDERR.puts 'Delete event:           hey delete <event_id>'

  exit 1
end

# Test if required tools are available on the path
raise 'sqlite3 command was not found. Please install SQLite and ensure it is available on your PATH' unless system('which sqlite3 > /dev/null 2>&1')

# TODO: Read a config file instead of checking an environment variable
DB_FILE = ENV['INTERRUPT_TRACKER_DB'] || '~/interrupts.db'

INTERRUPTS_TABLE = 'interrupts'

if !File.exist?(File.expand_path(DB_FILE))
  cmd = "sqlite3 #{DB_FILE} 'CREATE TABLE #{INTERRUPTS_TABLE}(event_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL, start_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, reason TEXT);'"
  stdout, stderr, status = Open3.capture3(cmd)
  STDERR.puts unless stderr.nil? || stderr.empty?
end

usage() if ARGV.empty?
usage() if ARGV[0] == '--help'

if ARGV[0] == 'list'
  # TODO: Remove the '-column' flag and handle the pretty-printing ourselves
  # FIXME: Don't load the entire SELECT result into memory, e.g. use LIMIT x,y
  cmd = "sqlite3 -column -header #{DB_FILE} 'SELECT * FROM #{INTERRUPTS_TABLE} ORDER BY start_time;'"
  stdout, stderr, status = Open3.capture3(cmd)
  puts stdout
  STDERR.puts stderr unless stderr.nil? || stderr.empty?

  exit status.to_i
end

if ARGV[0] == 'reason'
  usage() if ARGV.length < 2

  event_id = ARGV[1].strip.to_i
  reason = (ARGV[2..-1] || []).join(' ').strip.gsub(/"/, '')

  cmd = "sqlite3 #{DB_FILE} 'UPDATE #{INTERRUPTS_TABLE} SET reason = \"#{reason}\" WHERE event_id = #{event_id};'"
  stdout, stderr, status = Open3.capture3(cmd)
  STDERR.puts stderr unless stderr.nil? || stderr.empty?

  exit status.to_i
end

if ARGV[0] == 'delete'
  usage() if ARGV.length < 2

  event_id = ARGV[1].strip.to_i

  cmd = "sqlite3 #{DB_FILE} 'DELETE FROM #{INTERRUPTS_TABLE} WHERE event_id = #{event_id};'"
  stdout, stderr, status = Open3.capture3(cmd)
  STDERR.puts stderr unless stderr.nil? || stderr.empty?

  exit status.to_i
end

# Create a new event
name = ARGV[0].strip.downcase.gsub(/"/, '')
reason = (ARGV[1..-1] || []).join(' ').strip.gsub(/"/, '')

cmd = "sqlite3 #{DB_FILE} 'INSERT INTO #{INTERRUPTS_TABLE}(name, reason) VALUES(\"#{name}\", \"#{reason}\");'"
stdout, stderr, status = Open3.capture3(cmd)
STDERR.puts stderr unless stderr.nil? || stderr.empty?

exit status.to_i

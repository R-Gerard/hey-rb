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
  STDERR.puts 'Report on events:       hey report <report_type>'

  exit 1
end

# Test if required tools are available on the path
raise 'sqlite3 command was not found. Please install SQLite and ensure it is available on your PATH' unless system('which sqlite3 > /dev/null 2>&1')

# TODO: Read a config file instead of checking an environment variable
DB_FILE = ENV['INTERRUPT_TRACKER_DB'] || '~/interrupts.db'

INTERRUPTS_TABLE = 'interrupts'

REPORT_QUERIES = {
  'count' => {
    'description' => 'Total number of events in the database',
    'query' => "SELECT COUNT(*) AS total FROM #{INTERRUPTS_TABLE};",
    'flags' => ''
  },
  'names' => {
    'description' => 'Tabular results of events by name',
    'query' => "SELECT name, count(name) AS frequency FROM #{INTERRUPTS_TABLE} GROUP BY name ORDER BY frequency DESC;",
    'flags' => '-column -header'
  },
  'hourly' => {
    'description' => 'Tabular results of events by hour of the day',
    'query' => "SELECT hour, count(hour) AS frequency FROM (SELECT strftime('%H', start_time, 'localtime') AS hour FROM #{INTERRUPTS_TABLE}) GROUP BY hour ORDER BY hour;",
    'flags' => '-column -header'
  },
  'daily' => {
    'description' => 'Tabular results of events by day of the week',
    'query' => " SELECT CASE cast(strftime('%w', start_time, 'localtime') AS integer) WHEN 0 THEN 'SUN' WHEN 1 THEN 'MON' WHEN 2 THEN 'TUE' WHEN 3 THEN 'WED' WHEN 4 THEN 'THU' WHEN 5 THEN 'FRI' ELSE 'SAT' END AS day_of_week, count(event_id) AS frequency FROM #{INTERRUPTS_TABLE} GROUP BY day_of_week ORDER BY strftime('%w', start_time, 'localtime');",
    'flags' => '-column -header'
  }
}

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
  query = "SELECT event_id, name, datetime(start_time, 'localtime') AS start_time, reason FROM #{INTERRUPTS_TABLE} ORDER BY start_time;"
  cmd = "sqlite3 -column -header #{DB_FILE} \"#{query}\""
  stdout, stderr, status = Open3.capture3(cmd)
  puts stdout
  STDERR.puts stderr unless stderr.nil? || stderr.empty?

  exit status.to_i
end

if ARGV[0] == 'report'
  if ARGV.length < 2 || !REPORT_QUERIES.has_key?(ARGV[1])
    temp_hash = {
      'report_type' => {
        'description' => 'description'
      }
    }

    STDERR.puts "Usage: hey report <report_type>"
    STDERR.puts temp_hash.merge(REPORT_QUERIES).collect { |k,v| "  #{k.ljust(12)} #{v['description']}" }
    exit 1
  end

  query = REPORT_QUERIES[ARGV[1]]['query']
  flags = REPORT_QUERIES[ARGV[1]]['flags']
  cmd = "sqlite3 #{flags} #{DB_FILE} \"#{query}\""
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

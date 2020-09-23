#! /usr/bin/env ruby

def print_prompt()
  print("db > ")
end

def read_input()
  gets.chomp.downcase
end

def parse_meta_command(cmd)
  case cmd
  when "exit"
    exit
  else
    raise "Error"
  end
end

def parse_statement(statement)
  tokens = statement.split(/\s+/)
  case tokens.first.downcase
  when "select"
    puts "DO SELECT"
  when "insert"
    puts "DO INSERT"
  else
    raise "Error"
  end
end

def parse(str)
  if str[0] == "."
    parse_meta_command(str[1..-1])
  else
    parse_statement(str)
  end
rescue
  puts("Unrecognized command '#{str}'.")
end

while true do
  print_prompt()
  input = read_input()
  parse(input)
end

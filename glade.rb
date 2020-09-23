#! /usr/bin/env ruby

def print_prompt()
  print("db > ")
end

def read_input()
  gets.chomp.downcase
end

def parse(str)
  if str == ".exit"
    exit
  else
    puts("Unrecognized command '#{str}'.")
  end
end

while true do
  print_prompt()
  input = read_input()
  parse(input)
end

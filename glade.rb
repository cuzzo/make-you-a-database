#! /usr/bin/env ruby

class Table
  attr_reader :data

  def initialize()
    @data = []
  end

  def <<(obj)
    @data << serialize(obj)
  end

  def [](idx)
    deserialize(@data[idx])
  end

  def count()
    @data.count
  end

  private
  # Strings are 64 bytes
  def serialize(record)
    balance = Float(record[0])
    email = record[1][1...-1] # remove quotes
    [balance, email].pack("DA64")
  end

  def deserialize(bytes)
    bytes.unpack("DA64")
  end
end

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
    raise StandardError.new(:SyntaxError)
  end
end

# serialize record to bytes.
### figure out byte size / format by schema
### standard OS page size = 4096 bytes (4kb)
# store bytes in array.
def execute_insert(record)
  $table << record
  $table.count - 1
end

# move to position in memory.
# read size_of_record bytes.
# deserialize bytes to record.
def execute_select(id)
  $table[Integer(id)]
rescue
  raise StandardError.new(:SelectError)
end

def parse_statement(statement)
  tokens = statement.split(/\s+/)
  case tokens.first.downcase
  when "select"
    execute_select(tokens[1])
  when "insert"
    execute_insert(tokens[1..-1])
  else
    raise StandardError.new(:SyntaxError)
  end
end

def handle_error(e, str)
  case e.message.to_sym
  when :SyntaxError
    $stderr.puts("Unrecognized command '#{str}'.")
  when :SelectError
    $stderr.puts("Could not SELECT '#{str}'.")
  else
    $stderr.puts("System failure: '#{e.message}'.")
  end
end

def parse(str)
  if str[0] == "."
    parse_meta_command(str[1..-1])
  else
    resp = parse_statement(str)
    puts(resp)
  end
rescue => e
  handle_error(e, str)
end


$table = Table.new
while true do
  print_prompt()
  input = read_input()
  parse(input)
end

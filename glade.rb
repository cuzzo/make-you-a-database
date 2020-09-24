#! /usr/bin/env ruby

class InsertError < StandardError; end
class FetchError < StandardError; end
class SqlSyntaxError < StandardError; end
class SelectError < StandardError; end
class PageOverflowError < StandardError; end

class Cursor
  attr_reader :table
  attr_reader :row

  def initialize(table, row)
    @table = table
    @row = row
    @record_size = table.class.const_get(:RECORD_SIZE)
    @rows_per_page = Pager::PAGE_SIZE / @record_size
  end

  def self.to(table, pos=0)
    pos = table.num_rows - (pos + 1) if pos < 0
    new(table, pos)
  end

  def end?()
    row = table.num_rows
  end

  def read()
    page_num = row / @rows_per_page
    page = table.pager.get_page(page_num)

    page_offset = row % @rows_per_page
    byte_offset = page_offset * table.class.const_get(:RECORD_SIZE)

    serialized_record = page.slice(byte_offset, @record_size)
    table.deserialize(serialized_record)
  end

  def write(record)
    idx = row
    page_num = row / @rows_per_page
    page = table.pager.get_page(page_num)

    page_offset = row % @rows_per_page
    byte_offset = page_offset * table.class.const_get(:RECORD_SIZE)

    page[byte_offset, @record_size] = table.serialize(record)
    table.num_rows += 1

    idx
  end
end

class Pager
  attr_reader :file
  attr_reader :file_length

  def initialize(file_path)
    mode = File.exists?(file_path) ? "r+" : "w+"
    @file = File.open(file_path, mode)
    @file_length = @file.size
    @pages = PAGE_COUNT.times.map { |_| nil }
  end

  def write(record_idx, record_size, record_bytes)
    page_num, page_offset = page_idx(record_idx, record_size)
    page = get_page(page_num)
  end

  def close()
    # Write all data in the pages to disk
    @pages.each_with_index do |page, idx|
      next if page.nil?
      @file.seek(idx * PAGE_SIZE, IO::SEEK_SET)
      bytes_written = @file.write(page)
    end
    @file.close()
  end

  # Get the page, and page_idx for a record idx
  def get_page(idx)
    raise PageOverflowError.new("Cannot insert more records.") if idx >= PAGE_COUNT

    if @pages[idx].nil? # Cache miss
      num_saved_pages = @file_length / PAGE_SIZE

      # partial page can be saved at end of file...
      if @file_length % PAGE_SIZE
        num_saved_pages += 1
      end

      # if page exists, read it...
      if idx <= num_saved_pages
        @file.seek(idx * PAGE_SIZE, IO::SEEK_SET)
        page = @file.read(PAGE_SIZE)
      end

      # TODO: This could overwrite data if there's an error.
      page ||= [0].pack("C") * PAGE_SIZE

      @pages[idx] = page
    end

    @pages[idx]
  end

  PAGE_SIZE = 4096 # Standard OS-level page size
  PAGE_COUNT = 1000
end

class Table
  attr_reader :pager
  attr_accessor :num_rows

  def initialize(db_name)
    @pager = Pager.new(db_name)
    @num_rows = @pager.file_length / RECORD_SIZE
  end

  def close()
    @pager.close()
  end

  def serialize(record)
    balance = Float(record[0])
    email = record[1][1...-1] # remove quotes
    [balance, email].pack(FORMAT)
  end

  def deserialize(bytes)
    bytes.unpack(FORMAT)
  end

  private

  FORMAT = "DA64" # D[ecimal] A[rray]64
  RECORD_SIZE = 8 + 64 # Decimal (8, bytes) + A64 (Array, 64 bytes)
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
    $table.close()
    exit
  else
    raise SqlSyntaxError.new("Unsupported metacommand: '#{cmd}'.")
  end
end

def execute_insert(record)
  Cursor
    .to($table, -1)
    .write(record)
end

def execute_select(id)
  Cursor
    .to($table, Integer(id))
    .read()
rescue
  raise StandardError.new(:SelectError)
end

def parse_statement(statement)
  tokens = statement.split(/\s+/)
  case tokens.first.downcase.to_sym
  when :select
    execute_select(tokens[1])
  when :insert
    execute_insert(tokens[1..-1])
  else
    raise SqlSyntaxError.new("Unspported statement: '#{statement}'.")
  end
end

def handle_error(e, str)
  $stderr.puts(e)
end

def parse(str)
  if str[0] == "."
    parse_meta_command(str[1..-1])
  else
    parse_statement(str)
  end
rescue => e
  handle_error(e, str)
end


$table = Table.new("prod.db")
if $PROGRAM_NAME == __FILE__
  while true do
    print_prompt()
    input = read_input()
    resp = parse(input)
    puts(resp)
  end
end

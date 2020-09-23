require_relative "glade.rb"
require "byebug"

describe "glade" do
  before(:each) do
    $table = Table.new
  end

  it "inserts and retrieves a row" do
    result = parse_statement("INSERT 75.10 'yahn@google.com'")
    resp = parse_statement("SELECT #{result}")
    expect(resp[0]).to eq(75.10)
    expect(resp[1]).to eq("yahn@google.com")
  end

  it "inserts and retrieves multiple rows" do
    result1 = parse_statement("INSERT -15.25 'test@fakemail.com'")
    result2 = parse_statement("INSERT 100 'blah'")

    resp2 = parse_statement("SELECT #{result2}")
    resp1 = parse_statement("SELECT #{result1}")

    expect(resp2[0]).to eq(100)
    expect(resp2[1]).to eq("blah")

    expect(resp1[0]).to eq(-15.25)
    expect(resp1[1]).to eq("test@fakemail.com")
  end

  it "inserts strings of fixed length" do
    long = "a" * 64 # String limit
    long_email = "#{long}@breaking.com"

    result = parse_statement("INSERT 0 '#{long_email}'")
    resp = parse_statement("SELECT #{result}")

    expect(resp[0]).to eq(0)
    expect(resp[1]).to eq(long)
  end

  it "fails after limit is reached" do
    limit = 56 * 1000
    limit.times do |i|
      parse_statement("INSERT #{i} 'email-#{i}@gmail.com'")
    end

    expect {
      parse_statement("INSERT #{limit+1} 'over.the.limit@gmail.com'")
    }.to raise_error(
      an_instance_of(PageOverflowError)
        .and having_attributes(message: "Cannot insert more records.")
      )
  end
end

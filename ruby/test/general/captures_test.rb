#require 'rubygems'
require 'grok'
require 'test/unit'

class GrokPatternCapturingTests < Test::Unit::TestCase
  def setup
    @grok = Grok.new
  end

  def test_capture_methods
    @grok.add_pattern("foo", ".*")
    @grok.compile("%{foo}")
    match = @grok.match("hello world")
    assert_respond_to(match, :captures)
    assert_respond_to(match, :start)
    assert_respond_to(match, :end)
    assert_respond_to(match, :subject)
    assert_respond_to(match, :each_capture)
  end

  def test_basic_capture
    @grok.add_pattern("foo", ".*")
    @grok.compile("%{foo}")
    input = "hello world"
    match = @grok.match(input)
    assert_equal("(?<0000>.*)", @grok.expanded_pattern)
    assert_kind_of(Grok::Match, match)
    assert_kind_of(Hash, match.captures)
    assert_equal(match.captures.length, 1)
    assert_kind_of(Array, match.captures["foo"])
    assert_equal(1, match.captures["foo"].length)
    assert_kind_of(String, match.captures["foo"][0])
    assert_equal(input, match.captures["foo"][0])

    match.each_capture do |key, val|
      assert(key.is_a?(String), "Grok::Match::each_capture should yield string,string, got #{key.class.name} as first argument.")
      assert(val.is_a?(String), "Grok::Match::each_capture should yield string,string, got #{key.class.name} as first argument.")
    end

    assert_kind_of(Fixnum, match.start)
    assert_kind_of(Fixnum, match.end)
    assert_kind_of(String, match.subject)
    assert_equal(0, match.start,
                 "Match of /.*/, start should equal 0")
    assert_equal(input.length, match.end,
                 "Match of /.*/, end should equal input string length")
    assert_equal(input, match.subject)
  end

  def test_multiple_captures_with_same_name
    @grok.add_pattern("foo", "\\w+")
    @grok.compile("%{foo} %{foo}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(1, match.captures.length)
    assert_equal(2, match.captures["foo"].length)
    assert_equal("hello", match.captures["foo"][0])
    assert_equal("world", match.captures["foo"][1])
  end

  def test_multiple_captures
    @grok.add_pattern("foo", "\\w+")
    @grok.add_pattern("bar", "\\w+")
    @grok.compile("%{foo} %{bar}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["foo"].length)
    assert_equal(1, match.captures["bar"].length)
    assert_equal("hello", match.captures["foo"][0])
    assert_equal("world", match.captures["bar"][0])
  end

  def test_nested_captures
    @grok.add_pattern("foo", "\\w+ %{bar}")
    @grok.add_pattern("bar", "\\w+")
    @grok.compile("%{foo}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["foo"].length)
    assert_equal(1, match.captures["bar"].length)
    assert_equal("hello world", match.captures["foo"][0])
    assert_equal("world", match.captures["bar"][0])
  end

  def test_nesting_recursion
    @grok.add_pattern("foo", "%{foo}")
    assert_raises(ArgumentError) do
      @grok.compile("%{foo}")
    end
  end

  def test_valid_capture_subnames
    name = "foo"
    @grok.add_pattern(name, "\\w+")
    subname = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_abc:def"
    @grok.compile("%{#{name}:#{subname}}")
    match = @grok.match("hello")
    assert_not_equal(false, match)
    assert_equal(1, match.captures.length)
    assert_equal(1, match.captures["#{name}:#{subname}"].length)
    assert_equal("hello", match.captures["#{name}:#{subname}"][0])
  end

  def test_grok_inline_definition
    input = "key=123"
    @grok.compile("key=%{VALUE=\\d+}")
    match = @grok.match(input)
    assert_not_equal(false, match, "Expected '#{input}' to match '#{@grok.expanded_pattern}'")
    assert_equal(1, match.captures.length)
    assert_equal(1, match.captures["VALUE"].length)
    assert_equal("123", match.captures["VALUE"].first)
  end

  def test_grok_crazy_nested_inline_definition
    email = "something@some.host.name"
    input = "HELLO #{email}"
    #@grok[:logmask] = 0xffffff
    @grok.compile("HELLO %{EMAIL:email=[A-Za-z_+-]+@%{MYDOMAIN=some\\.host\\.name}}")
    match = @grok.match(input)
    assert_not_equal(false, match, "Expected '#{input}' to match '#{@grok.expanded_pattern}'")
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["EMAIL:email"].length)
    assert_equal(email, match.captures["EMAIL:email"].first)
  end

  def test_grok_nested_inline_definition
    email = "something@some.host.name"
    input = "HELLO #{email}"
    @grok.add_pattern("MYDOMAIN", "some\\.host\\.name")
    #@grok[:logmask] = 0xffffff
    @grok.compile("HELLO %{EMAIL:email=[A-Za-z_+-]+@%{MYDOMAIN}}")
    match = @grok.match(input)
    assert_not_equal(false, match, "Expected '#{input}' to match '#{@grok.expanded_pattern}'")
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["EMAIL:email"].length)
    assert_equal(email, match.captures["EMAIL:email"].first)
  end

  # TODO(sissel): This doesn't work yet.
  def __test_grok_inline_definition_with_predicate
    input = "key=123"
    @grok[:logmask] = 0xffffff
    @grok.compile("key=%{VALUE=\\d+ == 123}")
    match = @grok.match(input)
    assert_not_equal(false, match, "Expected '#{input}' to match '#{@grok.expanded_pattern}'")
    assert_equal(1, match.captures.length)
    assert_equal(1, match.captures["VALUE"].length)
    assert_equal("123", match.captures["VALUE"].first)
  end
end
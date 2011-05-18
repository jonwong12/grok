require "rubygems"
require "ffi"

class Grok < FFI::Struct
  attr_accessor :pattern
  attr_accessor :expanded_pattern
  
  PATTERN_RE = \
    /%{    # match '%{' not prefixed with '\'
     (?<name>     # match the pattern name
       (?<pattern>[A-z0-9]+)
       (?::(?<subname>[A-z0-9_:]+))?
     )}/x

  GROK_OK = 0
  GROK_ERROR_FILE_NOT_ACCESSIBLE = 1
  GROK_ERROR_PATTERN_NOT_FOUND = 2
  GROK_ERROR_UNEXPECTED_READ_SIZE = 3
  GROK_ERROR_COMPILE_FAILED = 4
  GROK_ERROR_UNINITIALIZED = 5
  GROK_ERROR_PCRE_ERROR = 6
  GROK_ERROR_NOMATCH = 7

  public
  def initialize
    #super(grok_new)
    @patterns = {}
  end # def initialize

  public
  def add_pattern(name, pattern)
    @patterns[name] = pattern
    return nil
  end

  public
  def add_patterns_from_file(path)
    file = File.new(path, "r")
    file.each do |line|
      next if line =~ /^\s*#/
      name, pattern = line.gsub(/^\s*/, "").split(/\s+/, 2)
      add_pattern(name, pattern)
    end
    return nil
  end # def add_patterns_from_file

  public
  def compile(pattern)
    @capture_map = {}

    iterations_left = 100
    @expanded_pattern = pattern
    index = 0

    # Replace any instances of '%{FOO}' with that pattern.
    loop do
      if iterations_left == 0
        raise "Deep recursionon pattern compilation of #{pattern.inspect}"
      end
      iterations_left -= 1
      m = PATTERN_RE.match(@expanded_pattern)
      break if !m

      if @patterns.include?(m["pattern"])
        # create a named capture index that we can push later as the named
        # pattern. We do this because ruby regexp can't capture something
        # by the same name twice.
        p = @patterns[m["pattern"]]
        capture = "a#{index}" # named captures have to start with letters?
        replacement_pattern = "(?<#{capture}>#{p})"
        @capture_map[capture] = m["name"]
        @expanded_pattern.gsub!(m[0], replacement_pattern)
        index += 1
      end
      p m => @expanded_pattern
      sleep 1
    end

    @regexp = Regexp.new(@expanded_pattern)
  end # def compile

  public
  def match(text)
    match = @regexp.match(text)

    if match
      grokmatch = Grok::Match.new
      grokmatch.subject = text
      grokmatch.match = match
    else
      return false
    end
  end # def match

  public
  def discover(input)
    init_discover if @discover == nil

    return @discover.discover(input)
  end

  private
  def init_discover
    @discover = GrokDiscover.new(self)
    @discover.logmask = logmask
  end
end # Grok

require "grok/match"
require "grok/pile"

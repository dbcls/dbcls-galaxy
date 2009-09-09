module GalaxyTool
  class ParseError < ArgumentError; end
  class RequiredOptionNotFoundError < ArgumentError; end
  class RejectedOptionError < ArgumentError; end
end

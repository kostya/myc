module Myc
  VERSION = "0.8.0-dev"
  COMMIT  = "-"
  EXT     = ".myc"
end

require "./*"
require "./cli/cli"

module Myc
  extend Stats
end

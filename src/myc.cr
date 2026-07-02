module Myc
  VERSION = "0.6.0-dev"
  COMMIT  = `git rev-parse --short HEAD`.chomp
  EXT     = ".myc"
end

require "./*"
require "./cli/cli"

module Myc
  extend Stats
end

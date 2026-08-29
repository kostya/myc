module Myc
  VERSION = "0.11.0-dev"
  COMMIT  = {{ `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`.chomp.stringify }}
  EXT     = ".myc"
end

require "./*"
require "./cli/cli"

module Myc
  extend Stats
end

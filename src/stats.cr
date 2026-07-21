module Myc::Stats
  def debug(subsystem, &)
    {% if !flag?(:release) %}
      if ENV["MYC_DEBUG"]? == "1"
        yield
      end
    {% end %}
  end

  TIMES = Hash(String, Float64).new(0.0)

  def measure(name, &)
    name = name.to_s
    t = Time.instant
    res = yield
    delta = (Time.instant - t).to_f
    if t = TIMES[name]?
      TIMES[name] = t + delta
    else
      TIMES[name] = delta
    end

    res
  end

  def print_timers
    if ENV["MYC_TIMERS"]? == "1"
      STDERR << "{"
      TIMES.each_with_index do |(k, v), i|
        STDERR << ", " if i != 0
        STDERR << "\"#{k}\": %.7f" % {v}
      end
      STDERR << "}"
    end
  end
end

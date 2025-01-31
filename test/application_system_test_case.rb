require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  using = ENV["CI"] ? :headless_chrome : :chrome
  driven_by :selenium, using: using, screen_size: [ 1400, 1400 ]
end

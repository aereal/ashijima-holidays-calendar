#!/usr/bin/env rackup

require './app'

use Rack::Static, urls: [], root: 'public', index: 'index.html'
run AshijimaHoliday::Web

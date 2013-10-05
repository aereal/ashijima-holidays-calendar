require './app'

task :import do
  include AshijimaHoliday
  holidays = Crawler.new.holidays
  DataService.import_holidays(DB, holidays)
end

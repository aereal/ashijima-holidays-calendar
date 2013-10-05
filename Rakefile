require './app'

include AshijimaHoliday

namespace :db do
  task :migrate do
    DB.create_table do
      primary_key :id
      column :start_on, :timestamp
      index :start_on, unique: true
    end
  end
end

task :import do
  holidays = Crawler.new.holidays
  DataService.import_holidays(DB, holidays)
end

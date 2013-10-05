require 'bundler' unless defined?(Bundler)
Bundler.require

module AshijimaHoliday
  DB = Sequel.connect('postgres://aereal@localhost/ashijima_holiday')

  class Crawler
    INFO_URL      = 'http://ashijimablog.com/%E5%AE%9A%E4%BC%91%E6%97%A5%E3%81%AE%E3%81%8A%E7%9F%A5%E3%82%89%E3%81%9B/'
    MONTH_PATTERN = /\((\d+)月\)/.freeze
    DAYS_PATTERN  = /(?:・?\d+\(.\))+/.freeze

    def crawled_document
      @crawled_document ||= Nokogiri.HTML(open(INFO_URL))
    end

    def extract_month
      m = crawled_document.css('.entry-title').text.match(MONTH_PATTERN)
      m && m[1]
    end

    def extract_days
      m = crawled_document.css('.entry-content > p').text.match(DAYS_PATTERN)
      m && m.to_s.split(/・/).map {|s| s[/(\d+)/, 1] }
    end

    def holidays
      year  = Time.now.year
      month = extract_month
      days  = extract_days
      holidays = days.map {|day| Time.new(year, month.to_i, day.to_i).to_datetime }
    end
  end

  class DataService
    # db - Sequel::Connection
    # holidays - [DateTime]
    def self.import_holidays(db, holidays)
      dataset = db[:holidays]
      holidays.each do |start_on|
        dataset.insert(start_on: start_on)
      end
    end

    def self.find_holidays_within(db, range)
      db[:holidays].where(start_on: range).order(:start_on).select_map(:start_on)
    end
  end

  module Calendar
    def self.build(holidays)
      Icalendar::Calendar.new.tap {|cal|
        holidays.each do |start_on|
          cal.event do
            summary '定休日'
            start start_on.to_datetime
          end
        end
        cal.publish
      }
    end
  end

  class Web < Sinatra::Base
    helpers do
      def within(year, month)
        from_at  = Time.new(year, month)
        until_at = Time.new(from_at.year, from_at.month + 1)
        from_at..until_at
      end
    end

    get %r{^/(?<year>\d{4})/(?<month>\d{2})/holidays[.](?<format>json|ical)$} do |year, month, format|
      holidays = DataService.find_holidays_within(DB, within(year, month))

      case format
      when 'json'
        content_type :json
        holidays_json = holidays.map {|d| { epoch: d.to_i, datetime: d.iso8601, date: d.strftime('%Y-%m-%d') } }
        { holidays: holidays_json }.to_json
      when 'ical'
        content_type 'text/calendar'
        Calendar.build(holidays).to_ical
      end
    end
  end
end

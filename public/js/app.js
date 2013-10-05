function latestMonthHolidaysURL() {
  var d = new Date();
  return (function (format) {
    return sprintf("/%d/%02d/holidays.%s", d.getFullYear(), d.getMonth() + 1, format);
  });
}

$(function () {
  var url = latestMonthHolidaysURL();
  var $getLatestHolidays = $('#get-latest-holidays');
  var templateSource = $getLatestHolidays.text();

  $.getJSON(url('json')).done(function (res) {
    var rendered = _.template(templateSource, { url: url('ical'), holidays: res.holidays });
    $getLatestHolidays.after(rendered);
  });
})

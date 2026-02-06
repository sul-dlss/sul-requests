# frozen_string_literal: true

###
#  Controller for creating csv reports on requests
###
class ReportsController < ApplicationController
  def index
    authorize! :read, :admin

    respond_to do |format|
      format.html {} # for rails
      format.csv do
        send_data(generate_csv_report, filename: "requests_report_#{Time.zone.today.strftime('%Y-%m-%d')}.csv")
      end
    end
  end

  private

  def group_by_list
    ['created_at.year', 'created_at.month', 'origin_location_code',
     *(params.key?(:request_type) ? ['type'] : []),
     *(params.key?(:service_point_code) ? ['service_point_code'] : [])]
  end

  def grouped_data
    PatronRequestSearch.call(params).group_by do |record|
      group_by_list.map do |path|
        path.split('.').inject(record) { |obj, m| obj&.public_send(m) }
      end
    end
  end

  def record_data(records)
    service_point_codes, types = records.map do |record|
      [record.service_point_code, record.display_type]
    end.transpose
    [service_point_codes.uniq.compact.join(', '), types.uniq.compact.join(', ')]
  end

  def csv_row(records)
    record = records.first
    service_point_codes, types = record_data(records)
    [record.created_at.year, record.created_at.month, types,
     Folio::Types.locations.find_by(code: record.origin_location_code)&.library&.name,
     record.origin_location_code, service_point_codes, records.count]
  end

  def generate_csv_report
    CSV.generate do |csv|
      csv << ['year', 'month', 'type', 'origin library', 'origin location', 'service point', 'count']

      grouped_data.each_value do |records|
        csv << csv_row(records)
      end
    end
  end
end

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
    origin_libraries
    destination_libraries
  end

  private

  def origin_libraries
    @origin_libraries ||= PatronRequest.all.map { |elem| Folio::Types.libraries.find_by(code: elem.origin_library_code) }.uniq
  end

  def destination_libraries
    @destination_libraries ||= PatronRequest.all.map do |elem|
      Folio::Types.service_points.find_by(code: elem.service_point_code)
    end.uniq.compact
  end

  # rubocop:disable Metrics/AbcSize
  def search_data
    start_date = Date.parse(params['start_date'])
    end_date = Date.parse(params['end_date'])
    @data = PatronRequest.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    @data = @data.where(service_point_code: params['service_point_code']) if params['service_point_code']

    @data = @data.select { |record| params['request_type'].include?(record.type.downcase) } if params['request_type']

    @data = @data.select { |record| params['origin_library_code'].include?(record.origin_library_code) } if params['origin_library_code']
    @data
  end
  # rubocop:enable Metrics/AbcSize

  def group_by_list
    ['created_at.year', 'created_at.month', 'origin_location_code',
     *(params.key?(:request_type) ? ['type'] : []),
     *(params.key?(:service_point_code) ? ['service_point_code'] : [])]
  end

  def grouped_data
    search_data.group_by do |record|
      group_by_list.map do |path|
        path.split('.').inject(record) { |obj, m| obj&.public_send(m) }
      end
    end
  end

  def record_data(records)
    service_point_codes, types = records.map do |record|
      [record.service_point_code, record.type]
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

# frozen_string_literal: true

# Common Symphony record model behaviors
class SymphonyBase
  attr_reader :response

  def initialize(response = {})
    @response = response || {}
  end

  def key
    response['key']
  end

  def exists?
    fields.present?
  end

  def fields
    response['fields'] || {}
  end

  def self.symphony_client
    SymphonyClient.new
  end

  def symphony_client
    @symphony_client ||= self.class.symphony_client
  end
end

# frozen_string_literal: true

# wrapper for getting SUL-specific icons to show up
class Icon
  attr_reader :icon_name

  ##
  # @param [String, Symbol] icon_name
  # @param [Hash] options
  # @param [String] classes additional classes separated by a string
  def initialize(icon_name, classes: '')
    @icon_name = icon_name
    @classes = classes
  end

  ##
  # Returns the raw source, but you could extend this to add additional attributes
  # @return [String]
  def svg
    file_source
  end

  ##
  # @return [Hash]
  def options
    {
      class: classes
    }
  end

  ##
  # @return [String]
  def path
    "icons/#{icon_name}.svg"
  end

  ##
  # @return [String]
  def file_source
    raise "Could not find #{path}" if file.blank?

    file.content.force_encoding('UTF-8')
  end

  private

  def file
    Rails.application.assets.load_path.find(path)
  end

  def classes
    " sul-icons #{@classes} ".strip
  end
end

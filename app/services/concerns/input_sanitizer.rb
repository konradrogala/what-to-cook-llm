module InputSanitizer
  extend ActiveSupport::Concern

  MAX_INPUT_LENGTH = 1000
  ALLOWED_CHARACTERS = /\A[a-zA-Z0-9\s,.()\-+'&\n]+\z/

  class InputError < StandardError; end

  def sanitize_input(input)
    case input
    when String
      raise InputError, "Ingredients cannot be empty" if input.strip.empty?
      sanitize_string(input)
    when Array
      raise InputError, "Ingredients cannot be empty" if input.empty?
      input.map { |item| sanitize_string(item.to_s) }
    else
      raise InputError, "Invalid input type. Expected String or Array, got #{input.class}"
    end
  end

  private

  def sanitize_string(str)
    str = str.to_s.strip

    if str.length > MAX_INPUT_LENGTH
      raise InputError, "Input exceeds maximum length of #{MAX_INPUT_LENGTH} characters"
    end

    unless str =~ ALLOWED_CHARACTERS
      raise InputError, "Input contains invalid characters"
    end

    CGI.escape_html(str)
  end
end

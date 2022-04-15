# frozen_string_literal: true

require_relative 'categories'
require 'json'
require 'digest/sha1'

class Engine
  class << self
    def run
      CATEGORIES.each_pair do |linter, categories|
        if categories.empty?
          warn "Error: Linter #{linter} does not have categories."
          exit!
        end

        diff = categories - (categories & VALID_CATEGORIES)
        unless diff.empty?
          warn "Error: Linter #{linter} have invalid categories: #{diff}"
          exit!
        end
      end

      data = $stdin.read
      begin
        data = JSON.parse(data)
      rescue JSON::ParserError
        warn 'Error: Received invalid input:'
        warn data
        exit!
      end

      puts data['Issues']&.map { |i| convert_issue(i) }&.join("\0")
    end

    ISSUE_IDENTIFIER_REGEXP = /^([^\s]+): (.*)/.freeze

    def convert_issue(i)
      text = i['Text']
      # Data coming from linters is not standardised, so it may be quite
      # complicated to extract a check_name and description from it. Here we
      # try to obtain something that resembles an identifier in a best effort
      # fashion.
      check_name = text
      linter_name = i['FromLinter']

      unless (m = ISSUE_IDENTIFIER_REGEXP.match(text)).nil?
        check_name = m[1]
      end

      {
        type: :issue,
        check_name: check_name,
        description: "#{linter_name}: #{text}",
        categories: categories_for_linter(linter_name),
        fingerprint: fingerprint_issue(i),
        location: locate_issue(i)
      }.to_json
    end

    def categories_for_linter(linter)
      CATEGORIES[linter]
    end

    def locate_issue(i)
      pos = i['Pos']
      {
        path: pos['Filename'],
        positions: {
          begin: {
            line: pos['Line'],
            column: pos['Column']
          },
          end: {
            line: pos['Line'] + i['SourceLines'].length,
            column: i['SourceLines'].last.length
          }
        }
      }
    end

    def fingerprint_issue(i)
      data = [
        i.dig('Pos', 'Filename'),
        i['Text'],
        i['SourceLines'].first
      ].join('')
      Digest::SHA1.hexdigest data
    end
  end
end

Engine.run

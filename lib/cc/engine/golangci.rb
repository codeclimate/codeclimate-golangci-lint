require_relative 'categories'
require 'pathname'
require 'json'
require 'digest/sha1'
require 'open3'

module CC
  module Engine
    class Golangci
      ALLOWED_EXTENSIONS = %w[.go]
      ISSUE_IDENTIFIER_REGEXP = /^([^\s]+): (.*)/.freeze

      def initialize(engine_config)
        @engine_config = engine_config || {}
        @files_to_analyze = []
        @dirs_to_analyze = []
      end

      attr_reader :engine_config

      def run
        issues = analyze_paths.compact

        puts output_issues(issues)
      end

      def analyze_paths
        # run the linter for each include_paths path
        # we do this because the linter is very strict and loud about the paths to analyze we provide as arguments
        # this method is noticeably slower than running the linter just once

        include_paths.flat_map do |path|
          real_path = Pathname.new(path).realpath

          if real_path.directory?
            path += "..."
          else
            next unless ALLOWED_EXTENSIONS.include?(real_path.extname)
          end

          issues = run_command(path)["Issues"]
          next unless issues.is_a?(Array) && issues.length > 0

          issues.map { |issue| process_issue(issue) }
        end
      end

      def run_command(path)
        data = IO.popen(command_env, command(path)).read
        return {} if data.nil? || data.empty?

        JSON.parse(data)
      rescue JSON::ParserError
        warn "Error parsing golangci-lint's output:"
        warn "#{data}"
        exit!
      end

      def command(path)
        ["/usr/local/bin/golangci-lint", "run", "--out-format", "json", path]
      end

      def command_env
        { "CGO_ENABLED" => "0" }
      end

      def output_issues(issues)
        issues.uniq { |issue| issue[:fingerprint] }.map { |issue| issue.to_json + "\0" }.join
      end

      def process_issue(issue)
        text = issue['Text']
        # Data coming from linters is not standardised, so it may be quite
        # complicated to extract a check_name and description from it. Here we
        # try to obtain something that resembles an identifier in a best effort
        # fashion.
        check_name = text
        linter_name = issue['FromLinter']

        unless (m = ISSUE_IDENTIFIER_REGEXP.match(text)).nil?
          check_name = m[1]
        end

        {
          type: :issue,
          check_name: check_name,
          description: "#{linter_name}: #{text}",
          categories: categories_for_linter(linter_name),
          fingerprint: fingerprint_issue(issue),
          location: locate_issue(issue)
        }
      end

      def categories_for_linter(linter)
        CATEGORIES[linter]
      end

      def locate_issue(issue)
        pos = issue['Pos']
        {
          path: pos['Filename'],
          positions: {
            begin: {
              line: pos['Line'],
              column: pos['Column']
            },
            end: {
              line: pos['Line'] + issue['SourceLines'].length,
              column: issue['SourceLines'].last.length
            }
          }
        }
      end

      def fingerprint_issue(issue)
        data = [
          issue.dig('Pos', 'Filename'),
          issue['Text'],
          issue['SourceLines'].first
        ].join('')
        Digest::SHA1.hexdigest data
      end

      private

      def include_paths
        @include_paths ||= engine_config["include_paths"]
      end
    end
  end
end

require_relative 'categories'
require 'pathname'
require 'json'
require 'digest/sha1'

module CC
  module Engine
    class Golangci
      ALLOWED_EXTENSIONS = %w[.go]

      def initialize(engine_config)
        @engine_config = engine_config || {}
        @files_to_analyze = []
        @dirs_to_analyze = []
      end

      attr_reader :engine_config, :dirs_to_analyze, :files_to_analyze

      def run
        build_paths_to_analyze

        run_for_paths(dirs_to_analyze)
        run_for_paths(files_to_analyze)
      end

      def run_for_paths(paths)
        data = IO.popen(command_env, command(paths)).read
        begin
          data = JSON.parse(data)
        rescue JSON::ParserError
          warn "Error parsing golangci-lint's output:"
          warn data
          exit!
        end

        issues = data["Issues"]
        return unless issues.is_a?(Array) && issues.length > 0
  
        puts data['Issues'].map { |issue| "#{convert_issue(issue)}\0" }.join
      end

      def command(paths)
        ["/usr/local/bin/golangci-lint", "run", "--out-format", "json", *paths]
      end

      def command_env
        { "CGO_ENABLED" => "0" }
      end

      ISSUE_IDENTIFIER_REGEXP = /^([^\s]+): (.*)/.freeze

      def convert_issue(issue)
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
        }.to_json
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

      def build_paths_to_analyze
        # golangci-lint surfaces errors when analyzing directories and files in the same run,
        # so we need to split the analysis into two different runs: one for directories and one for files

        include_paths = engine_config["include_paths"] || ["./"]

        include_paths.each do |path|
          begin
            pathname = Pathname.new(path).realpath

            if pathname.directory?
              # golangci-lint allows adding ... to a directory path to analyze it recursively
              # we want to do this for all directories

              @dirs_to_analyze << (pathname + "...").to_s
            else
              @files_to_analyze << pathname.to_s if ALLOWED_EXTENSIONS.include?(pathname.extname)
            end
          rescue Errno::ENOENT
            nil
          end
        end.compact
      end
    end
  end
end

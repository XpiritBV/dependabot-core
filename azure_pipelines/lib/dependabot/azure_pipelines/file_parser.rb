# frozen_string_literal: true

require "yaml"

require "dependabot/dependency"
require "dependabot/file_parsers"
require "dependabot/file_parsers/base"
require "dependabot/errors"
require "dependabot/github_actions/version"

module Dependabot
  module AzurePipelines
    class FileParser < Dependabot::FileParsers::Base
      require "dependabot/file_parsers/base/dependency_set"

      def parse
        dependency_set = DependencySet.new

        pipeline_files.each do |file|
          dependency_set += pipeline_file_dependencies(file)
        end

        # TODO: Task version resolution
        #resolve_git_tags(dependency_set)
        dependency_set.dependencies
      end

      private

      def pipeline_file_dependencies(file)
        dependency_set = DependencySet.new

        json = YAML.safe_load(file.content, aliases: true)
        task_strings = deep_fetch_task(json).uniq

        task_strings.each |task| do
          parsed = /('(?<id>[^@]+)'|"(?<id>[^@]+)")@(?<version>\d+(\.\d+){0,2})/.match(task).named_captures
          dependency_set << task_dependency(file, parsed.id, parsed.version) unless parsed.id.nil? || parsed.version.nil?
        end 

        dependency_set
      rescue Psych::SyntaxError, Psych::DisallowedClass, Psych::BadAlias
        raise Dependabot::DependencyFileNotParseable, file.path
      end

      def task_dependency(file, task_id, task_version)
        Dependency.new(
          name: task_id,
          version: version_class.new(task_version),
          requirements: [{
            requirement: nil,
            groups: [],
            source: {
              type: "git", #TODO: Set this to something more appropriate
              url: "", #TODO: Add during enrichment step when marketplace is queried
              ref: ref,
              branch: nil
            },
            file: file.name,
            metadata: { declaration_string: string }
          }],
          package_manager: "azure_pipelines"
        )
      end

      def deep_fetch_task(json_obj)
        case json_obj
        when Hash then deep_fetch_task_from_hash(json_obj)
        when Array then json_obj.flat_map { |o| deep_fetch_task(o) }
        else []
        end
      end

      def deep_fetch_task_from_hash(json_object)
        steps = json_object.fetch("steps", [])

        task_strings =
          if steps.is_a?(Array) && steps.all?(Hash)
            steps.
              map { |step| step.fetch("task", nil) }.
              select { |task| task.is_a?(String) }
          else
            []
          end

        task_strings +
          json_object.values.flat_map { |obj| deep_fetch_task(obj) }
      end

      def pipeline_files
        # The file fetcher only fetches pipeline files, so no need to
        # filter here
        dependency_files
      end

      def check_required_files
        # Just check if there are any files at all.
        return if dependency_files.any?

        raise "No pipeline files!"
      end

      def version_class
        AzurePipelines::Version
      end
    end
  end
end

Dependabot::FileParsers.
  register("azure_pipelines", Dependabot::AzurePipelines::FileParser)

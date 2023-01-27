# frozen_string_literal: true

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module AzurePipelines
    class FileFetcher < Dependabot::FileFetchers::Base
      FILENAME_PATTERN = /azure.*pipelines?.*\.ya?ml$/

      def self.required_files_in?(filenames)
        filenames.any? { |f| f.match?(FILENAME_PATTERN) }
      end

      def self.required_files_message
        "Repo must contain an azure-pipelines.yml/azure-pipelines.yaml file"
      end

      private

      def fetch_files
        fetched_files = []
        fetched_files += correctly_encoded_pipeline_files
        fetched_files += referenced_local_pipeline_files

        return fetched_files if fetched_files.any?

        if incorrectly_encoded_pipeline_files.none?
          expected_paths =
            if directory == "/"
              File.join(directory, "azure-pipelines.yml")
            else
              File.join(directory, "<anything>.yml")
            end

          raise(
            Dependabot::DependencyFileNotFound,
            expected_paths
          )
        else
          raise(
            Dependabot::DependencyFileNotParseable,
            incorrectly_encoded_pipeline_files.first.path
          )
        end
      end

      def pipeline_files
        return @pipeline_files if defined? @pipeline_files

        @pipeline_files = []

        # In the special case where the root directory is defined we also scan
        # the .github/pipelines/ folder.
        if directory == "/"
          @pipeline_files += [fetch_file_if_present("azure-pipelines.yml"), fetch_file_if_present("azure-pipelines.yaml")].compact
          pipelines_dir = "/"
        else
          pipelines_dir = "."
        end

        @pipeline_files +=
          repo_contents(dir: pipelines_dir, raise_errors: false).
          select { |f| f.type == "file" && f.name.match?(/\.ya?ml$/) }.
          map { |f| fetch_file_from_host("#{pipelines_dir}/#{f.name}") }
      end

      def referenced_local_pipeline_files
        # TODO: Fetch referenced local pipeline files
        []
      end

      def correctly_encoded_pipeline_files
        pipeline_files.select { |f| f.content.valid_encoding? }
      end

      def incorrectly_encoded_pipeline_files
        pipeline_files.reject { |f| f.content.valid_encoding? }
      end
    end
  end
end

Dependabot::FileFetchers.
  register("azure_pipelines", Dependabot::AzurePipelines::FileFetcher)

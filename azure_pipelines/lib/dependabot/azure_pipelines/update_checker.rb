# frozen_string_literal: true

require "dependabot/update_checkers"
require "dependabot/update_checkers/base"

module Dependabot
  module AzurePipelines
    class UpdateChecker < Dependabot::UpdateCheckers::Base

      def latest_version
        @available_version_fetcher.latest_version
      end

      def latest_resolvable_version
        # Not relevant for Azure Pipelines
        latest_version
      end

      def latest_resolvable_version_with_no_unlock
        # Not relevant for Azure Pipelines
        dependency.version
      end

      def updated_requirements # rubocop:disable Metrics/PerceivedComplexity
        return dependency.requirements
      end

      private

      def latest_version_resolvable_with_full_unlock?
        # Full unlock checks aren't relevant for Azure Pipelines
        false
      end

      def updated_dependencies_after_full_unlock
        raise NotImplementedError
      end

      def available_version_fetcher
        @available_version_fetcher ||=
          Dependabot::AzurePipelines::AvailableVersionFetcher.new(
            dependency: dependency, 
            credentials: credentials)
      end
    end
  end
end

Dependabot::UpdateCheckers.
  register("azure_pipelines", Dependabot::AzurePipelines::UpdateChecker)

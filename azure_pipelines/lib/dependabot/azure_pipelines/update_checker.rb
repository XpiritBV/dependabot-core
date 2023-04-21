# frozen_string_literal: true

require "json"
require "dependabot/update_checkers"
require "dependabot/update_checkers/base"
require "dependabot/shared_helpers"
require "dependabot/errors"

module Dependabot
  module AzurePipelines
    class UpdateChecker < Dependabot::UpdateCheckers::Base
      def latest_version
        @latest_version ||= fetch_latest_version
      end

      def latest_resolvable_version
        # Resolvability isn't an issue for GitHub Actions.
        latest_version
      end

      def latest_resolvable_version_with_no_unlock
        # No concept of "unlocking" for GitHub Actions (since no lockfile)
        dependency.version
      end

      def lowest_security_fix_version
        @lowest_security_fix_version ||= fetch_lowest_security_fix_version
      end

      def lowest_resolvable_security_fix_version
        # Resolvability isn't an issue for GitHub Actions.
        lowest_security_fix_version
      end

      def updated_requirements
        updated = updated_source

        dependency.requirements.map { |req| req.merge(source: updated) }
      end

      private

      def active_advisories

      end

      def latest_version_resolvable_with_full_unlock?
        # Full unlock checks aren't relevant for GitHub Actions
        false
      end

      def updated_dependencies_after_full_unlock
        raise NotImplementedError
      end

      def fetch_latest_version
        latest_version = latest_version_from_api.fetch(:version)
        return current_version if shortened_semver_eq?(dependency.version, latest_version.to_s)

        return latest_version
      end

      def fetch_lowest_security_fix_version

      end

      def find_lowest_secure_version(tags)
        relevant_tags = Dependabot::UpdateCheckers::VersionFilters.filter_vulnerable_versions(tags, security_advisories)
        relevant_tags = filter_lower_tags(relevant_tags)

        relevant_tags.min_by { |tag| tag.fetch(:version) }
      end

      def dependency_source_details
        sources =
          dependency.requirements.map { |r| r.fetch(:source) }.uniq.compact

        return sources.first if sources.count <= 1

        # If there are multiple source types, or multiple source URLs, then it's
        # unclear how we should proceed
        raise "Multiple sources! #{sources.join(', ')}" if sources.map { |s| [s.fetch(:type), s[:url]] }.uniq.count > 1

        # Otherwise it's reasonable to take the first source and use that. This
        # will happen if we have multiple git sources with difference references
        # specified. In that case it's fine to update them all.
        sources.first
      end

      def ado_checker(path)
        url = credentials.find { |cred| cred["type"] == "azure_devops_organization" }.fetch("url", nil) || nil
        @ado_checker ||= response = Dependabot::RegistryClient.get(
          url: url + path,
          headers: auth_header
        )
      end

      def auth_header
        token = credentials.find { |cred| cred["type"] == "azure_devops_organization" }.fetch("token", nil) || nil

        return {} unless token

        encoded_token = Base64.encode64(".:" + token).delete("\n")
        
        { "Authorization" => "Basic #{encoded_token}" }
      end

      def shortened_semver_eq?(base, other)
        return false unless base

        base_split = base.split(".")
        other_split = other.split(".")
        return false unless base_split.length <= other_split.length

        other_split[0..base_split.length - 1] == base_split
      end

      
    end
  end
end

Dependabot::UpdateCheckers.
  register("azure_pipelines", Dependabot::AzurePipelines::UpdateChecker)

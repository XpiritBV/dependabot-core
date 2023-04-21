# frozen_string_literal: true

require "dependabot/utils"

module Dependabot
  module AzurePipelines
    class Version < Gem::Version
      def initialize(version)
        super
      end

      def self.correct?(version)
        super
      end
    end
  end
end

Dependabot::Utils.
  register_version_class("azure_pipelines", Dependabot::AzurePipelines::Version)

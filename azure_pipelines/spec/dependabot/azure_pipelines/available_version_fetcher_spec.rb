# frozen_string_literal: true

require "spec_helper"
require "dependabot/azure_pipelines"

RSpec.describe Dependabot::AzurePipelines::AvailableVersionFetcher, :vcr do
    let(:credentials) { azdoBaseUrl: "https://dev.azure.com/dependabot", azdoToken: "test" }
    let(:dependency) { Dependabot::Dependency.new(id: "60faef65-3155-4b0a-98c3-3fae78775fb3", name: "dependabot", version: "v1.2.3", requirements: [], package_manager: "azure_pipelines") }
    let(:available_version_fetcher_instance) do
        Dependabot::AzurePipelines::AvailableVersionFetcher.new(dependency: dependency, credentials: credentials)
    end

    it "fetches the latest version" do
        expect(available_version_fetcher_instance.latest_version).to eq("v1.4.5")
    end
end

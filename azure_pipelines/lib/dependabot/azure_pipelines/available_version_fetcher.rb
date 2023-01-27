require "net/http"
require "json"

module Dependabot
    module AzurePipelines
        class AvailableVersionFetcher
            def initialize(dependency:, credentials:)
                @dependency = dependency
                @credentials = credentials
            end
    
            def latest_version
                return @latest_version ||= fetch_latest_version @credentials[:azDoUrl], @credentials[:token]
            end
            
            private

            def fetch_latest_version(azdoBaseUrl, token)
                uri = URI.parse(azdoBaseUrl)

                Net::HTTP.start(uri.host, uri.port,:use_ssl => true) do |http|
                    task = fetch_task(http, azdoBaseUrl, token)
                    versions = fetch_versions(http, azdoBaseUrl, token, task["id"])

                    return versions.max_by { |v| Gem::Version.new(v) }
                end
            end

            def fetch_task(http, azdoBaseUrl, token)
                allTasksUrl = "#{azdoBaseUrl}/_apis/distributedtask/tasks?api-version=5.1-preview.1"
                request = Net::HTTP::Get.new allTasksUrl
                request.basic_auth "", token
                response = http.request request
                
                case response
                when Net::HTTPSuccess then
                    body = JSON.parse(response.body)
                    task = get_matching_task(body["value"])
                else
                    raise "Failed to fetch #{url}: #{response.code} #{response.message}"
                end
            end

            def get_matching_task(values)
                values.each do |item|
                    if is_match(item, @dependency.name)
                        return item
                    

            def is_match(item, name)
                matchesName = item["name"] == name 
                matchesId = item["id"] == name 
                matchesContributionIdWithName = "#{item["contributionIdentifier"]}.#{item["name"]}" == name
                matchesContributionIdWithId = "#{item["contributionIdentifier"]}.#{item["name"]}" == name
                return matchesName || matchesId || matchesContributionIdWithName || matchesContributionIdWithId
            end

            def fetch_versions(http, azdoBaseUrl, token, task_id)
                versionsUrl = "#{azdoBaseUrl}/_apis/distributedtask/tasks/#{task_id}?allVersions=true"
                request = Net::HTTP::Get.new versionsUrl
                request.basic_auth "", token
                response = http.request request
                
                case response
                when Net::HTTPSuccess then
                    body = JSON.parse(response.body)
                    versions = body["value"].map { |item| "#{item["version"]["major"]}.#{item["version"]["major"]}.#{item["version"]["patch"]}" }
                    return versions
                else
                    raise "Failed to fetch #{url}: #{response.code} #{response.message}"
                end
            end
        end
    end
end
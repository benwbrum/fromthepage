require 'rdf/rdfa'

class Api::SchemaOrgController < Api::ApiController

  before_action :set_type, only: [:get_schema_type]

  def public_actions
    return [:get_schema_type, :get_schema_config]
  end

  def get_schema_type
    # uses cache to optimize next calls
    schemaType = Rails.cache.fetch(@type, expires_in: 72.hours) do
      rdfaToJsonld("http://schema.org/#{@type}")
    end
    render_serialized schemaType
  end

  def rdfaToJsonld(url)
    graph = RDF::Graph.load(url, format: :rdfa)
    context = JSON.parse %({
      "@context": {
        "schema":   "http://schema.org/",
        "owl": "http://www.w3.org/2002/07/owl#",
        "rdfa": "http://www.w3.org/ns/rdfa#",
        "rdf":  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#"
      }
    })
    compacted = nil
    JSON::LD::API::fromRdf(graph) do |expanded|
        compacted = JSON::LD::API.compact(expanded, context['@context'])
    end
    compacted.to_json
  end

  def get_schema_config
    file = File.open(File.join(File.dirname(__FILE__), "../../../public/files/tree.jsonld"))
    file_data = file.read
    file.close
    render plain: file_data
  end

  private
    def set_type
      params.permit(:type)
      @type = params[:type]
    end

end
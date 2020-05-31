require 'rdf/rdfa'

class Api::SchemaOrgController < Api::ApiController

  before_action :set_type, only: [:get_schema_type]

  def public_actions
    return [:get_schema_type]
  end

  def get_schema_type
    render_serialized rdfaToJsonld("http://schema.org/#{@type}")
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


  private
    def set_type
      params.permit(:type)
      @type = params[:type]
    end

end
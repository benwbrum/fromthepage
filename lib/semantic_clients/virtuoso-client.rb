require_relative '../http-client/http-client'
require "base64"
require 'json/ld'
require 'rdf/turtle'

class VirtuosoClient

  def initialize()
    @host = ENV['VIRTUOSO_HOST']
    @collection = ENV['VIRTUOSO_COLLECTION']
    @graph = ENV['VIRTUOSO_GRAPH']
    @user = ENV['VIRTUOSO_USER']
    @password = ENV['VIRTUOSO_PASSWORD']
  end

  def insert(jsonld_string)
      headers = {
          "Authorization": "Basic " + Base64.strict_encode64(@user + ":" + @password),
          "Content-Type": "application/sparql-query"
      }
      httpClient = HttpClient.new(@host, headers, 'raw')
      rdf_string = jsonldToRdf(jsonld_string)
      query = "INSERT IN GRAPH <#{ @graph }> { #{rdf_string} }"
      httpClient.do_post(@collection, {}, query)
  end

  def listSemanticContributions(filter = {})
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    entityType = (entityTypeSanitized = filter['entityType']) ? "FILTER (?entityType = #{ entityTypeSanitized }) " : ''
    propertyValue = (propertyValueSanitized = filter['propertyValue']) ? "FILTER regex(?propertyValue, '#{ propertyValueSanitized }', 'i') " : ''
    includeMatchedProperties = filter['includeMatchedProperties'] 
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?idNote ?entityType ?idMainEntity #{ includeMatchedProperties ? '?entityMatchingProperty' : '' }
        WHERE {
          ?idNote rdf:type schema:NoteDigitalDocument .
          ?idNote schema:mainEntity ?idMainEntity .
          ?idMainEntity rdf:type ?entityType #{ entityType }.
          ?idMainEntity ?entityMatchingProperty ?propertyValue #{ propertyValue }.
        }
    "
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def listEntities(filter)
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    entityType = (entityTypeSanitized = filter['entityType']) ? "FILTER (?entityType = #{ entityTypeSanitized }) " : ''
    propertyValue = (propertyValueSanitized = filter['labelValue']) ? "FILTER regex(?propertyValue, '#{ propertyValueSanitized }', 'i') " : ''
    includeMatchedProperties = filter['includeMatchedProperties'] 
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?entityId, ?entityType, ?entityLabel
        WHERE {
            ?entityId rdf:type ?entityType #{ entityType }.
            ?entityId rdfs:label ?entityLabel #{ propertyValue }.
        }
    "
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def describeEntity(id, useDefaultGraph = false)
    idSemanticContributionQuery = useDefaultGraph ? "#{@graph}/#{idSemanticContribution}" : idSemanticContribution
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    query = "
      #{ getPrefixes() }

      DESCRIBE <#{ idSemanticContributionQuery }>
    "
    response = do_query(query)
    (entity = response["data"].body) ? rdfToJsonld(entity, id) : nil
  end

  def describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    idSemanticContributionQuery = useDefaultGraph ? "#{@graph}/#{idSemanticContribution}" : idSemanticContribution
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    query = "
        #{ getPrefixes() }

        DESCRIBE ?mainEntityId
        WHERE {
          <#{idSemanticContributionQuery}> <http://schema.org/mainEntity> ?mainEntityId.
        }
    "
    response = do_query(query)
    (entity = response["data"].body) ? rdfToJsonld(entity, "transcriptor:#{idSemanticContribution}", true) : nil
  end

  private
    def do_query(query, format = "text/plain", serialize_reponse_format = format)
      httpClient = HttpClient.new(@host, {}, serialize_reponse_format)
      httpClient.do_post('/sparql', {}, {"query" => query, "default-graph-uri" => @graph, "format" => format })
    end

    def jsonldToRdf(jsonld_string)
      input = JSON.parse(jsonld_string)
      graph = RDF::Graph.new << JSON::LD::API.toRdf(input)
      graph.dump(:ntriples, validate: false)
    end

    def rdfToJsonld(rdf_string, element_id, is_container = false)
      graph = RDF::Graph.new << RDF::Turtle::Reader.new(rdf_string)
      context = JSON.parse %({
        "@context": {
          "schema":   "http://schema.org/",
          "rdf":  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
          "transcriptor": "#{ @graph }/"
        }
      })
      compacted = nil
      JSON::LD::API::fromRdf(graph) do |expanded|
        compacted = JSON::LD::API.compact(expanded, context['@context'])
      end
      flatCompacted(compacted, element_id, is_container).to_json
    end

    def flatCompacted(compacted, element_id, is_container = false)
      mainElement = nil
      for graphElement in compacted['@graph'] || []
        if (graphElement["@id"] == element_id)
          mainElement = graphElement
          mainElement['@context'] = compacted['@context']
          return is_container ? flatCompacted(compacted, mainElement['schema:mainEntity']['@id'], false) : mainElement
        end
      end
      return compacted
    end

    def getPrefixes()
      " PREFIX schema: <http://schema.org/>
        PREFIX transcriptor: <#{ @graph }/>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      "
    end
end

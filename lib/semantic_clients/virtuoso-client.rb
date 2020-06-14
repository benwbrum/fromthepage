require_relative '../http-client/http-client'
require_relative '../schema_helper'
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
    sanitizedFilter = sanitizeFilter(filter)
    entityType = (sanitizedFilter['entityType'] != nil) ? "FILTER (?entityType = #{ filter['entityType'] }) " : ''
    propertyValue = (sanitizedFilter['propertyValue'] != nil) ? "FILTER regex(?propertyValue, '#{ getSchemaReference(filter['propertyValue']) }', 'i') " : ''
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

  def listSemanticContributionsByEntity(filter = {})
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    sanitizedFilter = sanitizeFilter(filter)
    propertyValue = (sanitizedFilter['entityId'] != nil) ? "FILTER regex(?propertyValue, '#{ filter['entityId'] }', 'i') " : ''
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?idNote 
        WHERE {
            ?idNote rdf:type schema:NoteDigitalDocument .
            ?idNote schema:mainEntity #{ getTranscriptorReference(filter['entityId']) } .
        }
    "
    print query
    print '\n'
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def listEntities(filter)
    matchedEntityTypes = getEntityTypes(filter)
    sanitizedFilter = sanitizeFilter(filter)
    defaultTypeFilter = "FILTER (?entityDefaultType IN (#{ getEntityTypes({"entityType" => 'schema:Thing', "hierarchical" => true}).join(',') })) "
    entityType = (matchedEntityTypes != nil) ? "FILTER (?entityType IN (#{ matchedEntityTypes.join(',') }) && ?entityType != schema:NoteDigitalDocument) " : "FILTER (?entityType != schema:NoteDigitalDocument) "
    propertyValue = (sanitizedFilter['labelValue'] != nil) ? "FILTER regex(?entityLabel, #{ sanitizedFilter['labelValue'] }, 'i') " : ''
    limit = (sanitizedFilter['limit']  != nil) ? "LIMIT #{ sanitizedFilter['limit'] }" : ''
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?entityId, ?entityType, ?entityLabel
        WHERE {
            ?entityId rdf:type ?entityType #{ entityType }.
            ?entityId rdf:type ?entityDefaultType #{ defaultTypeFilter }.
            ?entityId rdfs:label ?entityLabel #{ propertyValue }.
        }
        #{limit}
    "
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def describeEntity(entityId, useDefaultGraph = false)
    entityIdQuery = useDefaultGraph ? "#{@graph}/#{entityId}" : entityId
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    query = "
      #{ getPrefixes() }

      DESCRIBE <#{ entityIdQuery }> ?p ?q
      WHERE {
        <#{ entityIdQuery }> ?p ?q
      }
    "
    response = do_query(query)
    (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, entityId), entityId) : nil
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
      flatCompacted(compacted, element_id, is_container)
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

    def sanitizeFilter(filter)
      sanitizedFilter = {}
      filter.each do |key, value|
        entitySanitized = ActiveRecord::Base.connection.quote(value)
        if (value && entitySanitized && entitySanitized != '')
          sanitizedFilter[key] = entitySanitized
        end
      end
      return sanitizedFilter
    end

    def getEntityItem(jsonld_hash, entityId)
      schemedEntityId = "transcriptor:#{entityId.split('/').last}" 
      jsonld_hash['@graph'].find{ |entityItem| entityItem['@id'] == schemedEntityId }
    end

    # Iterates over object taking relationships ID's and nesting that to make one compact object
    def compressEntityRelations(jsonld_hash, entityId)
      graph = jsonld_hash['@graph']
      entity = getEntityItem(jsonld_hash, entityId)
      entity.each do |property, value|
        if(value.is_a?(Hash) && value["@id"])
          entity[property] = graph.find{ |entityItem| entityItem['@id'] == value["@id"] }
        elsif value.is_a?(Array)
          processedArray = []
          value.each do | arrayMember |
            processedArray.push(arrayMember["@id"] ? graph.find{ |entityItem| entityItem['@id'] == arrayMember["@id"] } : arrayMember)
          end
          entity[property] = processedArray
        end
      end
    end

    def getEntityTypes(filter)
      if(filter['entityType'])
        matchedEntityType = SchemaHelper.getFullTypeHierarchy(filter['entityType'])
        if(matchedEntityType)
          return filter['hierarchical'] ? matchedEntityType : [filter['entityType']]
        end
        return nil
      end
      return nil
    end

    def getSchemaReference(stringReference)
      stringReference.gsub(/<|>/, '').gsub(/http:\/\/schema.org\//, 'schema:')
    end

    def getTranscriptorReference(stringReference)
      stringReference.gsub(/<|>/, '').gsub(@graph + "/", 'transcriptor:')
    end
end

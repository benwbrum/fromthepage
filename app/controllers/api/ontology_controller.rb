class Api::OntologyController < Api::ApiController

    before_action :set_ontology, only: [:update, :destroy]

    def create
        @ontology = Ontology.new
        @ontology.name = params[:ontology][:name]
        @ontology.description = params[:ontology][:description]
        @ontology.url = params[:ontology][:url]
        @ontology.domainkey = params[:ontology][:domainkey]
        @ontology.prefix = params[:ontology][:prefix]
        if @ontology.save
        render_serialized ResponseWS.ok("api.ontology.create.success",@ontology,alert)
        else
            render_serialized ResponseWS.default_error
        end
    end

    def update
        @ontology.update_attributes(params[:ontology].permit(:name,:description,:url,:domainkey,:prefix))
        render_serialized ResponseWS.ok("api.ontology.update.success",@ontology)
    end

    def destroy
        @ontology.destroy
        render_serialized ResponseWS.ok("api.ontology.destroy.success",@ontology)
    end
    
    
    def list
        @ontologies = Ontology.all
        response_serialized_object @ontologies
    end

    def set_ontology
        @ontology = Ontology.find(params[:id])
        raise ActiveRecord::RecordNotFound unless @ontology
    end
end
class OaiController < ApplicationController

  def identify_repository
    client = OAI::Client.new params[:repository_url]
    @identify_response = client.identify
  end

  def metadata_format_list
    client = OAI::Client.new params[:repository_url]
    @list_metadata_formats_response = client.list_metadata_formats
  end

  def set_list
    client = OAI::Client.new params[:repository_url]
    @list_sets_response = client.list_sets
  end

  def save_spec
    spec = OaiSet.new
    spec.set_spec = params[:set_spec]
    spec.repository_url = params[:repository_url]
    spec.user_id = current_user.id
    spec.save
    redirect_to dashboard_path
  end

  def record_list
    client = OAI::Client.new params[:repository_url]
    set_spec = params[:set_spec]
    @list_records_response =
      client.list_records({:metadata_prefix => 'oai_dc',
                           :set => set_spec})
    @repository_url = params[:repository_url]
    @set_spec = params[:set_spec]
  end

  def repository_list
    @repositories = OaiRepository.all
  end

end

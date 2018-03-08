require_relative 'http-client'

class MetagameClient < HttpClient

    def initialize(baseURL, token)
        headers = {"Authorization":'Token token="'+ token +'"'}
        super(baseURL,headers)
    end

    #### Players Methods #####

    def list_players(filters = {})
        do_get('/players', filters)
    end

    def get_player(id)
        do_get("/players/#{id}")
    end

    def add_player(email)
        do_post("/players",{email:email})
    end

    def update_player(id,email)
        do_put("/players/#{id}",{email:email})
    end

    def delete_player(id)
        do_delete("/players/#{id}")
    end

    def player_info(email)
        do_get("/player_info",{email:email})
    end

    #### Badges Methods ####

    def list_badges(filters = {})
        do_get("/badges",filters)
    end

    def add_badge(badge)
        do_post("/badges",badge)
    end

    def update_badge(badge)
        do_put("/badges",badge)
    end

    def delete_badge(id)
        do_delete("/badges/#{id}")
    end

    #### Issues Methods ####
    
    def add_issue(email,badge_id)
        do_post("/issues",{email:email,badge_id:badge_id})
    end
    
    def delete_issue(email,badge_id)
        do_delete("/issues",{email:email,badge_id:badge_id})
    end

    #### Records Methods ####

    def list_records(filters = {})
        do_get("/records", filters)
    end

    def list_records_type(type, filters = {})
        do_get("/records/#{type}",filters)
    end

    #### Activities Methods ####
    
    def make_activity(params)
        do_get("/activities",params)
    end
end

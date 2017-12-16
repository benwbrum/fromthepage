require 'gamification_clients/metagame-client'

class GamificationHelper

    @@project = ENV['METAGAME_PROJECT_NAME']
    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.loginEvent(email)
        puts("login event")
        has_badge=self._user_has_badge(email,"welcome-back")
        activity={"email":email,"project":@@project,"event":"login","count":1}
        @@metagameClient.make_activity(activity)
        return !has_badge
    end

    #### Creacion de cuenta ####
    def self.registerEvent(email)
        puts("register event")
        activity={"email":email,"project":@@project,"event":"login","count":1}
        @@metagameClient.make_activity(activity)
        return true
    end

    ##### creacion de proyecto ####
    def self.createCollectionEvent(email)
        self._try_assign_badge(email,"first-collection")
    end

    #### crear trabajo ####
    def self.createWorkEvent(email)
        self._try_assign_badge(email,"first-work")
    end

    #### subir colección ####
    def self.uploadWorkEvent(email)
        self._try_assign_badge(email,"first-upload")
    end

    #### mejorar el contenido de una transcripcion. ####
    def self.editTranscriptionEvent(email)
        self._try_assign_badge(email,"first-transcription-upgrade")
    end

    #### recuperar insignias y cosas que tiene ####
    def self.getPlayerInfoEvent(email)
        @@metagameClient.player_info(email)
    end
    
    ##
    ## METODOS INTERNOS ##
    ##
    #### Registra una actividad con los datos pasados por parametro ####
    private
    def self._recordActivityEvent(email,event,count)
        activity={"email":email,"project":@@project,"event":event,"count":count}
        @@metagameClient.make_activity(activity)
    end
    
    #### Obtiene una insignia por nombre ####
    private
    def self._get_badge(badge_name)
        badgesList=@@metagameClient.list_badges({name:badge_name,project:@@project})
        badgesList.first
    end
    
    #### intenta asignar la insignia al usuario respondiendo si pudo ####
    private
    def self._try_assign_badge(email,badge_name)
        badge=self._get_badge(badge_name)
        response=@@metagameClient.add_issue(email,badge.id)
        if response.respond_to?("ok")
            return true
        end
        return false
    end
    
    private
    def self._user_has_badge(email,badge_name)
        response=self.getPlayerInfoEvent(email)
        if(response.player.respond_to?("badges"))
            response.player.badges.any?{ |badge| badge.name == badge_name }
        else
            return false
        end
    end
end

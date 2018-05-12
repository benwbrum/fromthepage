require 'gamification_clients/metagame-client'

class GamificationHelper

    @@project = ENV['METAGAME_PROJECT_NAME']
    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.loginEvent(email)
      puts("login event")
      begin  
        activity={"email":email,"project":@@project,"event":"login","count":1}
        @@metagameClient.make_activity(activity)
        response=self._user_has_badge(email,"welcome-back") ? nil : self._badge_notification("welcome-back")
        return response
      rescue Exception => e
        puts e.message
        return nil
      end  
    end

    #### Creacion de cuenta ####
    def self.registerEvent(email)
      puts("register event")
      begin  
        activity={"email":email,"project":@@project,"event":"login","count":1}
        @@metagameClient.make_activity(activity)
        return self._badge_notification("i-was-here")
      rescue Exception => e
        puts e.message
        return nil
      end  
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
      begin  
        badge=self._get_badge(badge_name)
        response=@@metagameClient.add_issue(email,badge.id)
        if response.respond_to?("ok")
            return self._badge_notification(badge_name)
        end
        return nil
      rescue Exception => e
        puts e.message
        return nil
      end
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
    
    private
    def self._badge_notification(badge_name)
      return Alert.new("badges.#{badge_name}.notification.title","badges.#{badge_name}.notification.message")
    end
end

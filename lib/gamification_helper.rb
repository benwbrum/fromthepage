require 'gamification_clients/metagame-client'

class GamificationHelper

    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.loginEvent(mail)
        puts(mail)
        puts("login event")
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @@metagameClient.make_activity(activity)
    end

    #### Creacion de cuenta ####
    def self.registerEvent(mail)
        puts(mail)
        puts("register event")
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @@metagameClient.make_activity(activity)
    end

    ##### creacion de proyecto ####
    def self.createCollectionEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"contribution","count":1}
        @@metagameClient.make_activity(activity)
    end

    #### crear trabajo ####
    def self.createWorkEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"contribution","count":1}
        @@metagameClient.make_activity(activity)
    end

    #### subir colección ####
    def self.uploadWorkEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"contribution","count":1}
        @@metagameClient.make_activity(activity)
    end

    #### mejorar el contenido de una transcripcion. ####
    def self.editTranscriptionEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"contribution","count":1}
        @@metagameClient.make_activity(activity)
    end

    #### recuperar insignias y cosas que tiene ####
    def self.getPlayerInfoEvent(mail)
        @@metagameClient.player_info(mail)
    end

end

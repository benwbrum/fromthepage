require 'gamification_clients/metagame-client'

class GamificationHelper

    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.loginEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)
    end

    #### Creacion de cuenta ####
    def self.registerEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"register","count":1}
        @metagameClient.make_activity(activity)
    end

    ##### creacion de proyecto ####
    def self.newProjectEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"new_project","count":1}
        @metagameClient.make_activity(activity)
    end

    #### crear trabajo ####
    def self.createWorkEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"new_work","count":1}
        @metagameClient.make_activity(activity)
    end

    #### subir colección ####
    def self.pushCollectionEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"push_collection","count":1}
        @metagameClient.make_activity(activity)
    end

    #### mejorar el contenido de una transcripcion. ####
    def self.upgradeTranscriptionEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"upgrade_transcription","count":1}
        @metagameClient.make_activity(activity)
    end

    #### recuperar insignias y cosas que tiene ####
    def self.getBadgesEvent(mail)
        filters={"project":"cientopolis","email":mail}
        @metagameClient.list_badges(filters)
    end

    def self.clientParams
        puts ENV['METAGAME_URL']
    end

end

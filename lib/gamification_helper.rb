require 'gamification_clients/metagame-client'

class GamificationHelper

    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    def self.loginEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)

    end

    def self.registerEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"register","count":1}
        @metagameClient.make_activity(activity)
    end

    def self.newProjectEvent()
        activity={"email":mail,"project":"cientopolis","event":"new_project","count":1}
        @metagameClient.make_activity(activity)
    end

    def self.createWorkEvent()
        activity={"email":mail,"project":"cientopolis","event":"createWork","count":1}
        @metagameClient.make_activity(activity)
    end

    def self.pushCollectionEvent()
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)
    end

    def self.upgradeTranscriptionEvent()
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)
    end

    def self.getBadgesEvent()
    end

    def self.clientParams
        puts ENV['METAGAME_URL']
    end

end

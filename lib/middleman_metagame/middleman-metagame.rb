class MiddlemanMetagame

    def initialize()
        #Deberia tomar los params de la config
        @metagameClient = MetagameClient.new("URL","token")

    end

    def loginEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)

    end

    def registerEvent(mail)
        activity={"email":mail,"project":"cientopolis","event":"register","count":1}
        @metagameClient.make_activity(activity)
    end

    def newProjectEvent()
        activity={"email":mail,"project":"cientopolis","event":"new_project","count":1}
        @metagameClient.make_activity(activity)
    end

    def createWorkEvent()
        activity={"email":mail,"project":"cientopolis","event":"createWork","count":1}
        @metagameClient.make_activity(activity)
    end

    def pushCollectionEvent()
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)
    end

    def upgradeTranscriptionEvent()
        activity={"email":mail,"project":"cientopolis","event":"login","count":1}
        @metagameClient.make_activity(activity)
    end

    def getBadgesEvent()
    end


end


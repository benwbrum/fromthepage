require 'gamification_clients/metagame-client'

class SetUpBadges

    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.addBadges()
        badgeNewProject={"name":"first-contribution","project":"cientopolis","type":"new_project"}
        badgeRegister={"name":"first-contribution","project":"cientopolis","type":"register","points":1}
        badgeNewWork={"name":"first-contribution","project":"cientopolis","type":"new_work","points":1}
        badgePushCollection={"name":"first-contribution","project":"cientopolis","type":"push_collection","points":1}
        badgeUpgradeTranscription={"name":"first-contribution","project":"cientopolis","type":"upgrade_transcription","points":1}

        @metagameClient.add_badge(badgeNewProject)
        @metagameClient.add_badge(badgeRegister)
        @metagameClient.add_badge(badgeNewWork)
        @metagameClient.add_badge(badgePushCollection)
        @metagameClient.add_badge(badgeUpgradeTranscription)

    end

  

end

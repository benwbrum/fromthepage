require 'gamification_clients/metagame-client'

class SetUpBadges

    @@metagameClient = MetagameClient.new(ENV['METAGAME_URL'],ENV['METAGAME_TOKEN'])

    #### login diario ####
    def self.addBadges()
       # badgeNewProject={"name":"first-contribution","project":"cientopolis","type":"new_project"}
        badgeNewWork={"name":"first-contribution","project":"cientopolis","type":"new_work"}
        badgePushCollection={"name":"first-contribution","project":"cientopolis","type":"push_collection"}
        badgeUpgradeTranscription={"name":"first-contribution","project":"cientopolis","type":"upgrade_transcription"}

     #   @metagameClient.add_badge(badgeNewProject)
        @metagameClient.add_badge(badgeNewWork)
        @metagameClient.add_badge(badgePushCollection)
        @metagameClient.add_badge(badgeUpgradeTranscription)

    end

  

end

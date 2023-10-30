module ProjectsHelper
    def show_project_snippet?(project, user)
      CollectionBlock.find_by(collection_id: project.id, user_id: user.id).nil?
    end
end

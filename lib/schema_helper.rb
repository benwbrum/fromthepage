require "json"

class SchemaHelper

    @@tree = nil
    @@types_hierarchy = Hash.new
    @@full_types_hierarchy = Hash.new

    def self.get_tree
        if (!@@tree)
            @@tree = create_tree()
            load_type_hierarchy(@@tree)
            load_full_type_hierarchy(@@tree)
        end
        @@tree
    end
    
    def self.load_type_hierarchy(baseElement, parents = [])
        parents.push(baseElement["@id"])
        @@types_hierarchy[baseElement["@id"]] = Hash.new 
        @@types_hierarchy[baseElement["@id"]]["parents"] = parents
        @@types_hierarchy[baseElement["@id"]]["children"] = [baseElement["@id"]]
        if baseElement.key?("children")
            for childElement in baseElement["children"] do
                @@types_hierarchy[baseElement["@id"]]["children"].push(childElement["@id"])
                load_type_hierarchy(childElement, parents.clone)
            end
        end
    end

    def self.load_full_type_hierarchy(baseElement = get_tree())
        children = []
        if baseElement.key?("children")
            for childElement in baseElement["children"] do
                children.concat(load_full_type_hierarchy(childElement))
            end
        end
        return @@full_types_hierarchy[baseElement["@id"]] = children.push(baseElement["@id"])
    end

    def self.getTypeHierarchy(type)
        get_tree()
        @@types_hierarchy[type]
    end

    def self.getFullTypeHierarchy(type)
        get_tree()
        @@full_types_hierarchy[type]
    end

    private
        def self.create_tree
            file = File.open(File.join(File.dirname(__FILE__), "../public/files/tree.jsonld"))
            data = JSON.load file
            file.close
            return data
        end

end

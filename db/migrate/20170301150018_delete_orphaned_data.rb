class DeleteOrphanedData < ActiveRecord::Migration
  def change
    #delete works for which there is no collection
    Work.all.each {|w| w.destroy unless w.collection}
    
    #delete pages for which there are no works
    Page.all.each {|p| p.destroy unless p.work}
    
    #delete document sets for which there is no collection
    DocumentSet.all.each {|d| d.destroy unless d.collection}

    #delete notes for which there is no collection
    Note.all.each {|n| n.destroy unless n.collection}

    #delete articles for which there is no collection
    Article.all.each {|a| a.destroy unless a.collection}

    #delete work statistics for which there is no work
    WorkStatistic.all.each {|s| s.destroy unless s.work}

    #delete ia works for which there is no work
    IaWork.all.each {|i| i.destroy unless i.work}

    #delete omeka items for which there is no work
    OmekaItem.all.each {|i| i.destroy unless i.work}

    #delete sc manifests for which there is no work
    ScManifest.all.each {|s| s.destroy unless s.work}

    #delete sections for which there is no work
    Section.all.each {|s| s.destroy unless s.work}

    #delete ia leaves for which there is no page
    IaLeaf.all.each {|i| i.destroy unless i.page}

    #delete omeka files for which there is no page
    OmekaFile.all.each {|o| o.destroy unless o.page}

    #delete sc canvases for which there is no page
    ScCanvas.all.each {|s| s.destroy unless s.page}

    #delete table cells for which there is no page
    TableCell.all.each {|t| t.destroy unless t.page}

    #delete tex figures for which there is no page
    TexFigure.all.each {|t| t.destroy unless t.page}
  end
end

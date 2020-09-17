class WorkSearch < FortyFacets::FacetSearch
  model 'WorkFacet'


  facet :s1, name: 'Text 1', order: :downcase
  facet :s2, name: 'Text 2', order: :downcase
  facet :s3, name: 'Text 3', order: :downcase
  facet :s4, name: 'Text 4', order: :downcase
  facet :s5, name: 'Text 5', order: :downcase


  # eventually these should be ranges as follows
  # range :d1, name: 'Date 1'
  # range :d2, name: 'Date 2'
  facet :d1, name: 'Date 1'
  facet :d2, name: 'Date 2'

end

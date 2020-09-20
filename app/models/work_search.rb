class WorkSearch < FortyFacets::FacetSearch
  model 'WorkFacet'

  facet :s1, name: 'Text 1'
  facet :s2, name: 'Text 2'
  facet :s3, name: 'Text 3'
  facet :s4, name: 'Text 4'
  facet :s5, name: 'Text 5'

  # eventually these should be ranges as follows
  # range :d1, name: 'Date 1'
  # range :d2, name: 'Date 2'
  facet :d1, name: 'Date 1'
  facet :d2, name: 'Date 2'
end

class WorkSearch < FortyFacets::FacetSearch

  model 'WorkFacet'

  facet :s0, name: 'Text 0'
  facet :s1, name: 'Text 1'
  facet :s2, name: 'Text 2'
  facet :s3, name: 'Text 3'
  facet :s4, name: 'Text 4'
  facet :s5, name: 'Text 5'
  facet :s6, name: 'Text 6'
  facet :s7, name: 'Text 7'
  facet :s8, name: 'Text 8'
  facet :s9, name: 'Text 9'

  range :d0, name: 'Date 0'
  range :d1, name: 'Date 1'
  range :d2, name: 'Date 2'

  facet [:work, :collection_id]

end

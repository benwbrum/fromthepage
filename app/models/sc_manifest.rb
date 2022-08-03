class ScManifest < ApplicationRecord
  belongs_to :work, optional: true
  belongs_to :sc_collection, optional: true
  belongs_to :collection, optional: true

  has_many :sc_canvases

  attr_accessor :service
  attr_accessor :v3_hash

  # TEST_MANIFEST = <<EOI
  # {"@id":"http://manifests.ydc2.yale.edu/manifest/BeineckeMS525","@type":"sc:Manifest","label":"New Haven, Beinecke Rare Book and Manuscript Library, Yale University, Beinecke MS 525","logo":"http://deliver.odai.yale.edu/content/assetid/355a55719512e9bbea820f73e248fb11fbc3918c/format/1","attribution":"Beinecke Rare Book and Manuscript Library, Yale University","license":"http://creativecommons.org/licenses/by/3.0/","related":{"@id":"http://brbl-dl.library.yale.edu/vufind/Record/3729218","label":"Beinecke Rare Book and Manuscript Library, Yale University catalog entry"},"metadata":[{"label":"Date","value":"s. XIII/XIV"},{"label":"Description","value":"Beinecke MS 525.5 (Fragment of Book of Hours)"},{"label":"Dimensions","value":"245 x 170 mm"},{"label":"Number of leaves","value":"frag."},{"label":"Material","value":"parchment"},{"label":"Language","value":"Latin"}],"sequences":[{"@id":"http://manifests.ydc2.yale.edu/sequence/BeineckeMS525","@type":"sc:Sequence","canvases":[{"@id":"http://manifests.ydc2.yale.edu/canvas/7ac64c8f-2cee-40dd-a637-b9244fda7154","@type":"sc:Canvas","height":"3329","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/bd5232be-146b-4a19-b9e4-d365d094c10d","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/7ac64c8f-2cee-40dd-a637-b9244fda7154","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/bd5232be-146b-4a19-b9e4-d365d094c10d/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3329","label":"Beinecke MS 525.1, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/bd5232be-146b-4a19-b9e4-d365d094c10d/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2566"}}],"label":"Beinecke MS 525.1, recto","width":"2566"},{"@id":"http://manifests.ydc2.yale.edu/canvas/70d44087-1cf4-45d2-87c3-283c7e41aad9","@type":"sc:Canvas","height":"3312","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/d71ab9b5-84f9-4326-b1f8-9b53f2d418f9","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/70d44087-1cf4-45d2-87c3-283c7e41aad9","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/d71ab9b5-84f9-4326-b1f8-9b53f2d418f9/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3312","label":"Beinecke MS 525.1, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/d71ab9b5-84f9-4326-b1f8-9b53f2d418f9/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2553"}}],"label":"Beinecke MS 525.1, verso","width":"2553"},{"@id":"http://manifests.ydc2.yale.edu/canvas/2842ba48-c8e2-4544-9a07-9ab73941a8a4","@type":"sc:Canvas","height":"901","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/ddac0b8a-5301-4556-ab98-005b9157541c","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/2842ba48-c8e2-4544-9a07-9ab73941a8a4","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/ddac0b8a-5301-4556-ab98-005b9157541c/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"901","label":"Beinecke MS 525.2, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/ddac0b8a-5301-4556-ab98-005b9157541c/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1095"}}],"label":"Beinecke MS 525.2, recto","width":"1095"},{"@id":"http://manifests.ydc2.yale.edu/canvas/a2139b0d-d9f3-4223-8499-d29d0961289d","@type":"sc:Canvas","height":"929","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/eb5c700d-444e-45e5-83ac-093782cb9fd8","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/a2139b0d-d9f3-4223-8499-d29d0961289d","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/eb5c700d-444e-45e5-83ac-093782cb9fd8/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"929","label":"Beinecke MS 525.2, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/eb5c700d-444e-45e5-83ac-093782cb9fd8/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1122"}}],"label":"Beinecke MS 525.2, verso","width":"1122"},{"@id":"http://manifests.ydc2.yale.edu/canvas/a09cc251-aa9e-433b-8ae8-8017144389c1","@type":"sc:Canvas","height":"2775","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/cb9678a2-fc22-4ac8-a75d-897d126052db","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/a09cc251-aa9e-433b-8ae8-8017144389c1","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/cb9678a2-fc22-4ac8-a75d-897d126052db/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2775","label":"Beinecke MS 525.3, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/cb9678a2-fc22-4ac8-a75d-897d126052db/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1978"}}],"label":"Beinecke MS 525.3, recto","width":"1978"},{"@id":"http://manifests.ydc2.yale.edu/canvas/90452a89-f466-4cc6-ad60-0436933c679d","@type":"sc:Canvas","height":"2756","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/4ab837b6-0060-44bc-8f9f-2887be1f9c89","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/90452a89-f466-4cc6-ad60-0436933c679d","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/4ab837b6-0060-44bc-8f9f-2887be1f9c89/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2756","label":"Beinecke MS 525.3, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/4ab837b6-0060-44bc-8f9f-2887be1f9c89/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1947"}}],"label":"Beinecke MS 525.3, verso","width":"1947"},{"@id":"http://manifests.ydc2.yale.edu/canvas/e2aaa556-0a49-4a08-a725-505c2cbed79f","@type":"sc:Canvas","height":"5104","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/7727651d-b15c-434d-b029-f723dba3b139","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/e2aaa556-0a49-4a08-a725-505c2cbed79f","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/7727651d-b15c-434d-b029-f723dba3b139/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"5104","label":"Beinecke MS 525.4, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/7727651d-b15c-434d-b029-f723dba3b139/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"3688"}}],"label":"Beinecke MS 525.4, recto","width":"3688"},{"@id":"http://manifests.ydc2.yale.edu/canvas/5d837e89-9a10-4f3d-a196-5430aa46f307","@type":"sc:Canvas","height":"5115","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/a35305b3-b81a-4806-a917-263ad758234b","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/5d837e89-9a10-4f3d-a196-5430aa46f307","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/a35305b3-b81a-4806-a917-263ad758234b/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"5115","label":"Beinecke MS 525.4, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/a35305b3-b81a-4806-a917-263ad758234b/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"3722"}}],"label":"Beinecke MS 525.4, verso","width":"3722"},{"@id":"http://manifests.ydc2.yale.edu/canvas/7b4c45bc-774d-43dd-ab77-be11c51beb82","@type":"sc:Canvas","height":"3952","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/e0c83c67-f983-4649-92b0-b4c23e150a0d","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/7b4c45bc-774d-43dd-ab77-be11c51beb82","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/e0c83c67-f983-4649-92b0-b4c23e150a0d/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3952","label":"Beinecke MS 525.5, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/e0c83c67-f983-4649-92b0-b4c23e150a0d/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2734"}}],"label":"Beinecke MS 525.5, recto","width":"2734"},{"@id":"http://manifests.ydc2.yale.edu/canvas/ea9f25c1-fe50-4892-bed7-3cfa69ec4057","@type":"sc:Canvas","height":"3940","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/6a681887-f467-4f1a-919c-3882165a4164","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/ea9f25c1-fe50-4892-bed7-3cfa69ec4057","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/6a681887-f467-4f1a-919c-3882165a4164/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3940","label":"Beinecke MS 525.5, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/6a681887-f467-4f1a-919c-3882165a4164/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2735"}}],"label":"Beinecke MS 525.5, verso","width":"2735"},{"@id":"http://manifests.ydc2.yale.edu/canvas/2b2c8221-df86-45e2-accf-ed645e25ce39","@type":"sc:Canvas","height":"2754","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/1b02b43b-a6f5-4941-ab19-3ab90d53ff33","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/2b2c8221-df86-45e2-accf-ed645e25ce39","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/1b02b43b-a6f5-4941-ab19-3ab90d53ff33/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2754","label":"Beinecke MS 525.6, recto [Beinecke MS 525.6 Book of Hours, with miniatures of St. Anthony and St. Claudius]","service":{"@id":"http://scale.ydc2.yale.edu/iiif/1b02b43b-a6f5-4941-ab19-3ab90d53ff33/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1821"}}],"label":"Beinecke MS 525.6, recto [Beinecke MS 525.6 Book of Hours, with miniatures of St. Anthony and St. Claudius]","width":"1821"},{"@id":"http://manifests.ydc2.yale.edu/canvas/90ddc62f-81de-43ef-9068-3dbd5826910f","@type":"sc:Canvas","height":"2754","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/4edcc89b-9dc1-4a17-ab3f-a2fdc3ab6716","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/90ddc62f-81de-43ef-9068-3dbd5826910f","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/4edcc89b-9dc1-4a17-ab3f-a2fdc3ab6716/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2754","label":"Beinecke MS 525.6, verso [Beinecke MS 525.6 Book of Hours, with miniatures of St. Anthony and St. Claudius]","service":{"@id":"http://scale.ydc2.yale.edu/iiif/4edcc89b-9dc1-4a17-ab3f-a2fdc3ab6716/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1832"}}],"label":"Beinecke MS 525.6, verso [Beinecke MS 525.6 Book of Hours, with miniatures of St. Anthony and St. Claudius]","width":"1832"},{"@id":"http://manifests.ydc2.yale.edu/canvas/2776662d-ab33-4e9e-9207-caa587801967","@type":"sc:Canvas","height":"2701","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/8f13d795-191e-4e24-82a2-433dc48e0e84","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/2776662d-ab33-4e9e-9207-caa587801967","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/8f13d795-191e-4e24-82a2-433dc48e0e84/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2701","label":"Beinecke MS 525.7, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/8f13d795-191e-4e24-82a2-433dc48e0e84/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1836"}}],"label":"Beinecke MS 525.7, recto","width":"1836"},{"@id":"http://manifests.ydc2.yale.edu/canvas/11b5dd33-6eaa-4bdb-a3ad-7eec83984cd0","@type":"sc:Canvas","height":"2708","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/55a2ac35-c657-47bc-a09d-1c1d96770dcf","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/11b5dd33-6eaa-4bdb-a3ad-7eec83984cd0","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/55a2ac35-c657-47bc-a09d-1c1d96770dcf/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2708","label":"Beinecke MS 525.7, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/55a2ac35-c657-47bc-a09d-1c1d96770dcf/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1831"}}],"label":"Beinecke MS 525.7, verso","width":"1831"},{"@id":"http://manifests.ydc2.yale.edu/canvas/f41cc7fc-d993-4eed-bd7f-47cf3b979697","@type":"sc:Canvas","height":"2688","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/2866fd7d-b652-445e-8449-2f187c9c0a57","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/f41cc7fc-d993-4eed-bd7f-47cf3b979697","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/2866fd7d-b652-445e-8449-2f187c9c0a57/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2688","label":"Beinecke MS 525.8, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/2866fd7d-b652-445e-8449-2f187c9c0a57/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1830"}}],"label":"Beinecke MS 525.8, recto","width":"1830"},{"@id":"http://manifests.ydc2.yale.edu/canvas/36d1c3d8-dd74-4683-ae17-3a5e379e565d","@type":"sc:Canvas","height":"2697","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/c13aff17-d39e-4e45-9b52-ff8c63ceb375","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/36d1c3d8-dd74-4683-ae17-3a5e379e565d","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/c13aff17-d39e-4e45-9b52-ff8c63ceb375/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2697","label":"Beinecke MS 525.8, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/c13aff17-d39e-4e45-9b52-ff8c63ceb375/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1834"}}],"label":"Beinecke MS 525.8, verso","width":"1834"},{"@id":"http://manifests.ydc2.yale.edu/canvas/857d7af3-9a00-4dd1-b992-621637970b76","@type":"sc:Canvas","height":"2727","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/5f5e86c7-2ad0-49eb-b37c-fee2c6a1c802","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/857d7af3-9a00-4dd1-b992-621637970b76","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/5f5e86c7-2ad0-49eb-b37c-fee2c6a1c802/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2727","label":"Beinecke MS 525.9, 1r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/5f5e86c7-2ad0-49eb-b37c-fee2c6a1c802/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1931"}}],"label":"Beinecke MS 525.9, 1r","width":"1931"},{"@id":"http://manifests.ydc2.yale.edu/canvas/d4bafcc1-2777-434a-8af3-dd61b73213f1","@type":"sc:Canvas","height":"2700","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/5dcc6ae1-f37f-4b0e-a6a1-656a05dd960c","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/d4bafcc1-2777-434a-8af3-dd61b73213f1","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/5dcc6ae1-f37f-4b0e-a6a1-656a05dd960c/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2700","label":"Beinecke MS 525.9, 1v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/5dcc6ae1-f37f-4b0e-a6a1-656a05dd960c/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1749"}}],"label":"Beinecke MS 525.9, 1v","width":"1749"},{"@id":"http://manifests.ydc2.yale.edu/canvas/abd6abee-dfe5-414d-8e04-5154803cc27b","@type":"sc:Canvas","height":"2704","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/1e901dc8-3882-42ec-a214-4dc1b379f974","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/abd6abee-dfe5-414d-8e04-5154803cc27b","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/1e901dc8-3882-42ec-a214-4dc1b379f974/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2704","label":"Beinecke MS 525.9, 2r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/1e901dc8-3882-42ec-a214-4dc1b379f974/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1917"}}],"label":"Beinecke MS 525.9, 2r","width":"1917"},{"@id":"http://manifests.ydc2.yale.edu/canvas/b60b16a4-1839-41a4-a987-57634039033b","@type":"sc:Canvas","height":"2704","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/0e288b5b-6dc3-47f5-94bf-597f3d706447","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/b60b16a4-1839-41a4-a987-57634039033b","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/0e288b5b-6dc3-47f5-94bf-597f3d706447/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2704","label":"Beinecke MS 525.9, 2v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/0e288b5b-6dc3-47f5-94bf-597f3d706447/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1724"}}],"label":"Beinecke MS 525.9, 2v","width":"1724"},{"@id":"http://manifests.ydc2.yale.edu/canvas/3b48ea46-00d7-4f55-953b-f2118a309325","@type":"sc:Canvas","height":"2714","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/62fc51b0-a2ef-48d5-829f-83b6ecbf322f","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/3b48ea46-00d7-4f55-953b-f2118a309325","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/62fc51b0-a2ef-48d5-829f-83b6ecbf322f/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2714","label":"Beinecke MS 525.9, 3r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/62fc51b0-a2ef-48d5-829f-83b6ecbf322f/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1914"}}],"label":"Beinecke MS 525.9, 3r","width":"1914"},{"@id":"http://manifests.ydc2.yale.edu/canvas/6c14199b-ecca-427b-9437-d0fdaee3cb69","@type":"sc:Canvas","height":"2731","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/000fe0fa-522e-428e-a612-ea9f0ca00659","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/6c14199b-ecca-427b-9437-d0fdaee3cb69","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/000fe0fa-522e-428e-a612-ea9f0ca00659/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2731","label":"Beinecke MS 525.9, 3v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/000fe0fa-522e-428e-a612-ea9f0ca00659/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1714"}}],"label":"Beinecke MS 525.9, 3v","width":"1714"},{"@id":"http://manifests.ydc2.yale.edu/canvas/aa95fedf-fd54-4ed3-8b0a-26c6879c5440","@type":"sc:Canvas","height":"2743","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/dd05b3a3-ece0-4027-8e6f-0001ad3bd031","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/aa95fedf-fd54-4ed3-8b0a-26c6879c5440","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/dd05b3a3-ece0-4027-8e6f-0001ad3bd031/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2743","label":"Beinecke MS 525.9, 4r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/dd05b3a3-ece0-4027-8e6f-0001ad3bd031/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1900"}}],"label":"Beinecke MS 525.9, 4r","width":"1900"},{"@id":"http://manifests.ydc2.yale.edu/canvas/c8dc1387-ca63-459a-a46c-5b777b91b501","@type":"sc:Canvas","height":"2742","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/a5220293-bea0-4f30-a29b-11f5f3301809","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/c8dc1387-ca63-459a-a46c-5b777b91b501","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/a5220293-bea0-4f30-a29b-11f5f3301809/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2742","label":"Beinecke MS 525.9, 4v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/a5220293-bea0-4f30-a29b-11f5f3301809/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1745"}}],"label":"Beinecke MS 525.9, 4v","width":"1745"},{"@id":"http://manifests.ydc2.yale.edu/canvas/0848010d-f503-44fa-a3c1-8c13f8e4b7cf","@type":"sc:Canvas","height":"2713","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/775f22c6-b122-4866-b5d5-30a261cb9642","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/0848010d-f503-44fa-a3c1-8c13f8e4b7cf","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/775f22c6-b122-4866-b5d5-30a261cb9642/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2713","label":"Beinecke MS 525.9, 5r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/775f22c6-b122-4866-b5d5-30a261cb9642/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1816"}}],"label":"Beinecke MS 525.9, 5r","width":"1816"},{"@id":"http://manifests.ydc2.yale.edu/canvas/c54f104f-a0f4-4dee-8c3d-f3268f763ace","@type":"sc:Canvas","height":"2727","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/673673cf-17c0-42d6-ad10-2915162de2cd","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/c54f104f-a0f4-4dee-8c3d-f3268f763ace","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/673673cf-17c0-42d6-ad10-2915162de2cd/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2727","label":"Beinecke MS 525.9, 5v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/673673cf-17c0-42d6-ad10-2915162de2cd/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1884"}}],"label":"Beinecke MS 525.9, 5v","width":"1884"},{"@id":"http://manifests.ydc2.yale.edu/canvas/a92db886-e3cb-4b85-9b80-f30b87d2b80d","@type":"sc:Canvas","height":"2711","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/54785b47-3bab-4dc4-8b12-e666b2e7030b","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/a92db886-e3cb-4b85-9b80-f30b87d2b80d","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/54785b47-3bab-4dc4-8b12-e666b2e7030b/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2711","label":"Beinecke MS 525.9, 6r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/54785b47-3bab-4dc4-8b12-e666b2e7030b/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1819"}}],"label":"Beinecke MS 525.9, 6r","width":"1819"},{"@id":"http://manifests.ydc2.yale.edu/canvas/cde4b07f-b9f8-4096-a7f4-b95a37210e20","@type":"sc:Canvas","height":"2732","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/75fd43bf-39b8-4ec1-9d62-a3f5e38cee8f","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/cde4b07f-b9f8-4096-a7f4-b95a37210e20","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/75fd43bf-39b8-4ec1-9d62-a3f5e38cee8f/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2732","label":"Beinecke MS 525.9, 6v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/75fd43bf-39b8-4ec1-9d62-a3f5e38cee8f/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1888"}}],"label":"Beinecke MS 525.9, 6v","width":"1888"},{"@id":"http://manifests.ydc2.yale.edu/canvas/c7534926-be6c-424e-800c-a4797de9d980","@type":"sc:Canvas","height":"2699","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/6d36462b-45a5-4614-a436-1b087ecdfa0f","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/c7534926-be6c-424e-800c-a4797de9d980","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/6d36462b-45a5-4614-a436-1b087ecdfa0f/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2699","label":"Beinecke MS 525.9, 7r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/6d36462b-45a5-4614-a436-1b087ecdfa0f/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1814"}}],"label":"Beinecke MS 525.9, 7r","width":"1814"},{"@id":"http://manifests.ydc2.yale.edu/canvas/5f31832f-5a0e-4af6-87d2-bb1e4bdb9496","@type":"sc:Canvas","height":"2708","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/7db005d4-092f-41f0-bc55-237dd92c0073","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/5f31832f-5a0e-4af6-87d2-bb1e4bdb9496","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/7db005d4-092f-41f0-bc55-237dd92c0073/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2708","label":"Beinecke MS 525.9, 7v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/7db005d4-092f-41f0-bc55-237dd92c0073/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1933"}}],"label":"Beinecke MS 525.9, 7v","width":"1933"},{"@id":"http://manifests.ydc2.yale.edu/canvas/0fcb5f7f-e9ca-4987-a3f4-a94ff67aeb71","@type":"sc:Canvas","height":"2691","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/0508e965-cc68-469e-a632-156e1ca163f6","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/0fcb5f7f-e9ca-4987-a3f4-a94ff67aeb71","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/0508e965-cc68-469e-a632-156e1ca163f6/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2691","label":"Beinecke MS 525.9, 8r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/0508e965-cc68-469e-a632-156e1ca163f6/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1816"}}],"label":"Beinecke MS 525.9, 8r","width":"1816"},{"@id":"http://manifests.ydc2.yale.edu/canvas/dd8ca0d1-68b1-4607-82e0-f0e3b32abc98","@type":"sc:Canvas","height":"2752","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/8d041a18-072a-49a3-8364-c9d3ed844f20","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/dd8ca0d1-68b1-4607-82e0-f0e3b32abc98","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/8d041a18-072a-49a3-8364-c9d3ed844f20/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2752","label":"Beinecke MS 525.9, 8v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/8d041a18-072a-49a3-8364-c9d3ed844f20/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1931"}}],"label":"Beinecke MS 525.9, 8v","width":"1931"},{"@id":"http://manifests.ydc2.yale.edu/canvas/ea03c339-eeaf-40ff-9d16-687300a11040","@type":"sc:Canvas","height":"2761","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/16af445c-24fd-47f0-b488-6c48bdc86118","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/ea03c339-eeaf-40ff-9d16-687300a11040","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/16af445c-24fd-47f0-b488-6c48bdc86118/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2761","label":"Beinecke MS 525.9, 9r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/16af445c-24fd-47f0-b488-6c48bdc86118/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1958"}}],"label":"Beinecke MS 525.9, 9r","width":"1958"},{"@id":"http://manifests.ydc2.yale.edu/canvas/6a2061e8-260f-408f-ae36-d8fec81d7ae7","@type":"sc:Canvas","height":"2716","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/f03aa043-d297-4c02-afa1-8e2eb18d8633","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/6a2061e8-260f-408f-ae36-d8fec81d7ae7","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/f03aa043-d297-4c02-afa1-8e2eb18d8633/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2716","label":"Beinecke MS 525.9, 9v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/f03aa043-d297-4c02-afa1-8e2eb18d8633/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1899"}}],"label":"Beinecke MS 525.9, 9v","width":"1899"},{"@id":"http://manifests.ydc2.yale.edu/canvas/b77574ca-c5d6-481c-a1e3-3006b5e02644","@type":"sc:Canvas","height":"2744","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/f1eab1b7-17ef-4ba8-b3b3-4ff660e160b3","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/b77574ca-c5d6-481c-a1e3-3006b5e02644","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/f1eab1b7-17ef-4ba8-b3b3-4ff660e160b3/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2744","label":"Beinecke MS 525.9, 10r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/f1eab1b7-17ef-4ba8-b3b3-4ff660e160b3/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1923"}}],"label":"Beinecke MS 525.9, 10r","width":"1923"},{"@id":"http://manifests.ydc2.yale.edu/canvas/7a111517-3619-4080-881d-99e1535b6f7d","@type":"sc:Canvas","height":"2712","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/c44bde77-2889-452e-9b29-85a93bb8d39e","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/7a111517-3619-4080-881d-99e1535b6f7d","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/c44bde77-2889-452e-9b29-85a93bb8d39e/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2712","label":"Beinecke MS 525.9, 10v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/c44bde77-2889-452e-9b29-85a93bb8d39e/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1896"}}],"label":"Beinecke MS 525.9, 10v","width":"1896"},{"@id":"http://manifests.ydc2.yale.edu/canvas/20b45bb1-4ef7-4efc-9ee3-b7f35b027fad","@type":"sc:Canvas","height":"2719","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/8888485d-0d48-4196-89f8-d5fd508febce","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/20b45bb1-4ef7-4efc-9ee3-b7f35b027fad","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/8888485d-0d48-4196-89f8-d5fd508febce/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2719","label":"Beinecke MS 525.9, 11r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/8888485d-0d48-4196-89f8-d5fd508febce/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1872"}}],"label":"Beinecke MS 525.9, 11r","width":"1872"},{"@id":"http://manifests.ydc2.yale.edu/canvas/1ad6154c-23a4-406b-83d0-71e18ef150b9","@type":"sc:Canvas","height":"2704","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/e0e4b012-9946-400f-86a8-f32c87f0633e","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/1ad6154c-23a4-406b-83d0-71e18ef150b9","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/e0e4b012-9946-400f-86a8-f32c87f0633e/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2704","label":"Beinecke MS 525.9, 11v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/e0e4b012-9946-400f-86a8-f32c87f0633e/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1864"}}],"label":"Beinecke MS 525.9, 11v","width":"1864"},{"@id":"http://manifests.ydc2.yale.edu/canvas/d0050805-4ece-4a87-bd69-6090be141af2","@type":"sc:Canvas","height":"2708","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/98317613-77d2-4b99-9ade-fafe6552b845","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/d0050805-4ece-4a87-bd69-6090be141af2","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/98317613-77d2-4b99-9ade-fafe6552b845/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2708","label":"Beinecke MS 525.10, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/98317613-77d2-4b99-9ade-fafe6552b845/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1863"}}],"label":"Beinecke MS 525.10, recto","width":"1863"},{"@id":"http://manifests.ydc2.yale.edu/canvas/39e5eba7-921a-4799-969b-ed14a20791e5","@type":"sc:Canvas","height":"2716","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/6a9dd47d-1144-47fe-9e37-b0ab18708f28","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/39e5eba7-921a-4799-969b-ed14a20791e5","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/6a9dd47d-1144-47fe-9e37-b0ab18708f28/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2716","label":"Beinecke MS 525.10, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/6a9dd47d-1144-47fe-9e37-b0ab18708f28/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"1875"}}],"label":"Beinecke MS 525.10, verso","width":"1875"},{"@id":"http://manifests.ydc2.yale.edu/canvas/55a2b39a-2570-44e9-97e1-d779bb9eaae7","@type":"sc:Canvas","height":"2646","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/84cbddc6-6db5-4f22-880d-e890eb14b52f","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/55a2b39a-2570-44e9-97e1-d779bb9eaae7","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/84cbddc6-6db5-4f22-880d-e890eb14b52f/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2646","label":"Beinecke MS 525.11, recto","service":{"@id":"http://scale.ydc2.yale.edu/iiif/84cbddc6-6db5-4f22-880d-e890eb14b52f/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2551"}}],"label":"Beinecke MS 525.11, recto","width":"2551"},{"@id":"http://manifests.ydc2.yale.edu/canvas/e520681a-8cb4-47b7-b639-e41c1e1582dc","@type":"sc:Canvas","height":"2634","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/31840845-c29e-45f5-9493-5bb2ed6b1a09","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/e520681a-8cb4-47b7-b639-e41c1e1582dc","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/31840845-c29e-45f5-9493-5bb2ed6b1a09/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"2634","label":"Beinecke MS 525.11, verso","service":{"@id":"http://scale.ydc2.yale.edu/iiif/31840845-c29e-45f5-9493-5bb2ed6b1a09/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2567"}}],"label":"Beinecke MS 525.11, verso","width":"2567"},{"@id":"http://manifests.ydc2.yale.edu/canvas/185a5feb-73e6-427a-ae57-f28a7c204ab2","@type":"sc:Canvas","height":"3086","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/10265987-08ed-47be-8343-f7312a2b2739","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/185a5feb-73e6-427a-ae57-f28a7c204ab2","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/10265987-08ed-47be-8343-f7312a2b2739/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3086","label":"Beinecke MS 525.12, 1r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/10265987-08ed-47be-8343-f7312a2b2739/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2379"}}],"label":"Beinecke MS 525.12, 1r","width":"2379"},{"@id":"http://manifests.ydc2.yale.edu/canvas/d7218a44-6ddc-47f4-9ee9-f246b4135417","@type":"sc:Canvas","height":"3082","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/27e35a4d-6735-463b-8b44-0085f1c0b336","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/d7218a44-6ddc-47f4-9ee9-f246b4135417","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/27e35a4d-6735-463b-8b44-0085f1c0b336/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3082","label":"Beinecke MS 525.12, 1v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/27e35a4d-6735-463b-8b44-0085f1c0b336/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2368"}}],"label":"Beinecke MS 525.12, 1v","width":"2368"},{"@id":"http://manifests.ydc2.yale.edu/canvas/8d0bf6d9-e7e8-4636-958b-4e8b960af3de","@type":"sc:Canvas","height":"3107","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/326bec16-d5d9-4c3c-afb4-5fd278124088","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/8d0bf6d9-e7e8-4636-958b-4e8b960af3de","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/326bec16-d5d9-4c3c-afb4-5fd278124088/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3107","label":"Beinecke MS 525.12, 2r","service":{"@id":"http://scale.ydc2.yale.edu/iiif/326bec16-d5d9-4c3c-afb4-5fd278124088/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2413"}}],"label":"Beinecke MS 525.12, 2r","width":"2413"},{"@id":"http://manifests.ydc2.yale.edu/canvas/b3c05edd-a3da-4278-bd9a-f0dc12c2f448","@type":"sc:Canvas","height":"3088","images":[{"@id":"http://manifests.ydc2.yale.edu/annotation/a5b4a034-c9ef-45da-8dfb-5baed90ace00","@type":"oa:Annotation","motivation":"sc:painting","on":"http://manifests.ydc2.yale.edu/canvas/b3c05edd-a3da-4278-bd9a-f0dc12c2f448","resource":{"@id":"http://scale.ydc2.yale.edu/iiif/a5b4a034-c9ef-45da-8dfb-5baed90ace00/full/full/0/native.jpg","@type":"dctypes:Image","format":"image/jpeg","height":"3088","label":"Beinecke MS 525.12, 2v","service":{"@id":"http://scale.ydc2.yale.edu/iiif/a5b4a034-c9ef-45da-8dfb-5baed90ace00/","profile":"http://library.stanford.edu/iiif/image-api/1.1/conformance.html#level1"},"width":"2399"}}],"label":"Beinecke MS 525.12, 2v","width":"2399"}],"label":"BeineckeMS525","viewingDirection":"Left-to-Right"}],"@context":"http://www.shared-canvas.org/ns/context.json"}
  # EOI


  def self.manifest_for_at_id(at_id)
    connection = URI.open(at_id)
    manifest_json = connection.read
    #manifest_json = TEST_MANIFEST
    service = IIIF::Service.parse(manifest_json)

    if service['@type'] == "sc:Collection"
      raise ArgumentError, "#{at_id} contains a collection, not an item"
    end
    sc_manifest = ScManifest.new
    sc_manifest.at_id = at_id
    sc_manifest.label = ScManifest.cleanup_label(service.label)
    sc_manifest.service = service

    sc_manifest
  end

  def self.manifest_for_v3_hash(v3)
    if v3.is_a? String
      v3 = JSON.parse(v3)
    end
    sc_manifest = ScManifest.new
    sc_manifest.at_id = v3['id']
    sc_manifest.label = v3['label'].values.first.first
    sc_manifest.v3_hash = v3
    sc_manifest.version = '3'

    sc_manifest
  end

  def v3?
    self.version == '3'
  end

  def requiredStatement
    if v3?
      v3_hash['requiredStatement']
    else
      ""
    end
  end


  def metadata
    if v3?
      v3_hash['metadata']
    else
      service.metadata
    end
  end

  def description
    if v3?
      summary = v3_hash['summary']
      if summary.blank?
        ""
      else
        "TODO: implement summary"
      end
    else
      service.description
    end

  end

  def convert_with_sc_collection(user, sc_collection, annotation_ocr)
    collection = sc_collection.collection
    unless collection
      collection = Collection.new
      collection.owner = user
      collection.title = cleanup_label(sc_collection.label)
      collection.save!

      sc_collection.collection = collection
      sc_collection.save!
    end

    convert_with_collection(user, collection, nil, annotation_ocr)
  end

  def convert_with_no_collection(user, annotation_ocr)
    collection = Collection.new
    collection.owner = user
    collection.title = self.label.truncate(255, separator: ' ', omission: '')
    collection.save!
    convert_with_collection(user, collection, nil, annotation_ocr)
  end

  def items
    if self.v3?
      @v3_hash['items']
    else
      self.service.sequences.first.canvases
    end
  end

  def convert_with_collection(user, collection, document_set=nil, annotation_ocr=false)
    self.save!

    work = Work.new
    work.owner = user

    work.title = self.label
    work.description = self.html_description
    work.collection = collection
    work.original_metadata = normalize_metadata(self.metadata).to_json
    work.ocr_correction=annotation_ocr

    work.save!

    unless self.items.empty?
      self.items.each do |canvas|
        sc_canvas = manifest_canvas_to_sc_canvas(canvas)
        page = sc_canvas_to_page(sc_canvas, annotation_ocr)
        work.pages << page
        sc_canvas.page = page
        sc_canvas.save!
      end
    end
    work.save!
    record_deed(work)

    self.work = work
    self.save!

    if document_set
      document_set.works << work
    end

    work
  end

  def self.cleanup_label(label)
    label = flatten_element(label)
    new_label = label.truncate(255, separator: ' ', omission: '')
    new_label.gsub!("&quot;", "'")
    new_label.gsub!("&amp;", "&")
    new_label.gsub!("&apos;", "'")

    new_label
  end


  def pluck_language_value(raw)
    if raw.is_a? Hash
      raw = raw.values.first
      if raw.is_a? Array
        raw = raw.first
      end
    end
    raw
  end

  def normalize_metadata(raw)
    raw.map do |hash|
      # test for v3-style elements
      label = hash['label'] || hash['@label']
      label=pluck_language_value(label)
      value = hash['value'] || hash['@value']
      value = pluck_language_value(value)
      { '@label' => label, '@value' => value}
    end
  end

  def self.flatten_element(element)
    if element.is_a? Array
      element = element.first
    end
    if element.is_a? Hash
      element = element['@value'] || element['value']
    end
    element
  end


  def sc_canvas_to_page(sc_canvas, annotation_ocr=false)
    page = Page.new
    page.title = ScManifest.flatten_element(sc_canvas.sc_canvas_label)
    if annotation_ocr
      page.source_text=sc_canvas.annotation_text_for_source
    end

    page
  end


  def has_annotations?
    return false if v3?

    self.service.sequences.first.canvases.detect do |canvas|
      canvas.other_content && canvas.other_content.detect { |e| e['@type'] == "sc:AnnotationList" }
    end
  end

  def manifest_canvas_to_sc_canvas(canvas)
    sc_canvas = ScCanvas.new
    sc_canvas.sc_manifest =             self
    if self.v3?
      annotation_page = canvas['items'].first
      annotation = annotation_page['items'].first
      body = annotation['body']
      image_service = body['service'].first

      sc_canvas.sc_canvas_id =            canvas['id']
      sc_canvas.sc_service_id =           image_service['@id']
      sc_canvas.sc_resource_id =          body['id']
      sc_canvas.sc_service_context =      image_service['profile']
      sc_canvas.sc_canvas_label =         pluck_language_value(canvas['label'])
      sc_canvas.height =                  canvas['height']
      sc_canvas.width =                   canvas['width']
    else
      sc_canvas.sc_canvas_id =            canvas['@id']
      sc_canvas.sc_service_id =           canvas.images.first.resource.service['@id']
      sc_canvas.sc_resource_id =          canvas.images.first.resource['@id']
      sc_canvas.sc_service_context = canvas.images.first.resource.service['@context']
      sc_canvas.sc_canvas_label =         canvas.label
      sc_canvas.height = canvas.height
      sc_canvas.width = canvas.width
      if canvas.other_content && canvas.other_content.detect { |e| e['@type'] == "sc:AnnotationList" }
        sc_canvas.annotations = canvas.other_content.to_json
      end
    end

    sc_canvas.save!
    sc_canvas
  end

  def html_description
    description=self.description
    unless description.blank?
      description += ScManifest.flatten_element(self.description) + "\n<br /><br />\n"
    end

    description
  end


  def self.lang_keys_from_hash(hash)
    # expecting label/value pairs
    hash.first[1].keys
  end


  def self.lang_keys_from_object(object)
    lang_keys = []
    if object.is_a? Array
      lang_keys = object.map{ |hash| lang_keys_from_hash(hash) }.flatten
    else
      lang_keys = lang_keys_from_hash(hash)
    end
    lang_keys.tally
  end

  protected

  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = DeedType::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end
end

IMAGE_FILE_EXTENSIONS = ['jpg', 'JPG', 'jpeg', 'JPEG', 'png', 'PNG']
IMAGE_FILE_EXTENSIONS_PATTERN = /jpg|JPG|jpeg|JPEG|png|PNG/
TIFF_FILE_EXTENSIONS_PATTERN = /tif|TIF|tiff|TIFF/

INGESTOR_ALLOWLIST =  [
  'title',
  'identifier',
  'description',
  'restrict_scribes',
  'physical_description',
  'document_history',
  'permission_description',
  'location_of_composition',
  'author',
  'transcription_conventions',
  'scribes_can_edit_titles',
  'supports_translation',
  'translation_instructions',
  'pages_are_meaningful',
  'document_set',
  'slug'
].freeze

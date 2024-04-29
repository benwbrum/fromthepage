if defined? BENTO_ENABLED && BENTO_ENABLED
	$bento = Bento::Analytics.new(write_key: BENTO_ACCESS_TOKEN)
end
module dirserve

fn test_get_opt() {
	conf_file := 'config.toml'
	name := 'Movies'

	valid := get_opt(conf_file, name) or {
		eprintln('error: $err')
		assert false
		return
	}
	assert valid.name == name
	assert valid.upload == false

	get_opt(conf_file, 'Non-Existent') or {
		assert true
		assert '$err' == 'config Non-Existent not found in config file'
	}
}


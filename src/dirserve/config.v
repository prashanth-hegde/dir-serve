module dirserve

import toml
import os
import log { Log }

// mut logger := Log{level: .info}
pub struct ServeOpts {
pub:
	name        string [required]
	path        string [required]
	upload      bool
	recurse     bool
	show_hidden bool
mut:
	allow_types []string
	deny_types  []string
	log         Log = Log{
		level: .info
	}
}

pub fn (s ServeOpts) resolve_path(path string) string {
	// split the path into two parts
	// example: if path = localhost:8080/?path=Movies/test
	// then the tokens will be ['Movies', 'test']
	// The first token will always be the name of the share, and the
	// rest of it will be relative path to the share
	tokens := path.split_nth('/', 2)

	return if tokens.len > 1 {
		s.path + '/' + tokens[1]
	} else {
		s.path
	}
}

pub fn get_options(serve_opts []ServeOpts, path string) ?ServeOpts {
	if path == '' {
		return none
	}
	sanitized_path := path.split_nth('/', 2)[0]
	for s in serve_opts {
		if s.name == sanitized_path {
			return s
		}
	}
	return none
}

pub fn read_config(conf_file string) []ServeOpts {
	mut opts := []ServeOpts{}
	conf_file_abs := if conf_file[0] == `/` {
		conf_file
	} else {
		os.getwd() + os.path_separator + conf_file
	}

	conf := toml.parse_file(conf_file_abs) or {
		println('unable to read conf file contents, exiting...')
		exit(1)
	}

	if conf_file == '' {
		opts << read_default_config()
		return opts
	} else {
		for share in conf.value('shares').array() {
			allow_types := share.value('allow_types')
				.default_to('')
				.string()
				.split(',')
				.map(it.trim(' '))
				.filter(it != '')
				.map('.${it}')
			mut deny_types := share.value('deny_types')
				.default_to('')
				.string()
				.split(',')
				.map(it.trim(' '))
				.filter(it != '')
			if allow_types.len > 0 {
				// if allow types are defined, we are more restrictive
				// and only use allow list
				deny_types = []string{}
			}

			opts << ServeOpts{
				name: share.value('name').string()
				path: share.value('path').string()
				upload: share.value('upload').default_to(false).bool()
				recurse: share.value('recurse').default_to(false).bool()
				show_hidden: share.value('show_hidden').default_to(false).bool()
				allow_types: allow_types
				deny_types: deny_types
			}
		}
	}

	return opts
}

fn read_default_config() ServeOpts {
	return ServeOpts{
		name: 'pwd'
		path: os.getwd()
	}
}

fn get_opt(conf_file string, name string) !ServeOpts {
	opts := read_config(conf_file)
	if opts.len == 0 {
		return error('config file not found')
	}

	for o in opts {
		if o.name == name {
			return o
		}
	}
	return error('config ${name} not found in config file')
}

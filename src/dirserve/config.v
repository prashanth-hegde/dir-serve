module dirserve

import toml
import os

const log := &Log{.info}
pub struct ServeOpts {
pub:
	name        string @[required]
	path        string @[required]
	upload      bool
	recurse     bool
	show_hidden bool
mut:
	allow_types []string
	deny_types  []string
}

pub fn (s ServeOpts) resolve_path(path string) string {
	// split the path into two parts
	// example: if path = localhost:8080/?path=Movies/test
	// then the tokens will be ['Movies', 'test']
	// The first token will always be the name of the share, and the
	// rest of it will be relative path to the share
	if path == '' { return s.path }
	tokens := path.split_nth('/', 2)
	return if tokens.len > 1 {
		os.join_path(s.path, tokens[1])
	} else {
		s.path
	}
}

pub fn (s []ServeOpts) opt(relative_path string) ServeOpts {
	base_dir := relative_path.split_nth(os.path_separator, 2)
	return if relative_path == '' || base_dir.len == 0 {
		s.first()
	} else {
		for o in s {
			if o.name == base_dir[0] {
				return o
			}
		}
		s.first()
	}
}

pub fn read_config(conf_file string) []ServeOpts {
	mut opts := []ServeOpts{}
	conf_file_abs := if conf_file[0] == `/` {
		conf_file
	} else {
		os.join_path(os.getwd(), conf_file)
	}

	conf := toml.parse_file(conf_file_abs) or {
		eprintln('unable to read conf file contents, exiting...')
		exit(1)
	}

	if conf_file == '' {
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
				name:        share.value('name').string()
				path:        share.value('path').string()
				upload:      share.value('upload').default_to(false).bool()
				recurse:     share.value('recurse').default_to(false).bool()
				show_hidden: share.value('show_hidden').default_to(false).bool()
				allow_types: allow_types
				deny_types:  deny_types
			}
		}
	}

	return opts
}

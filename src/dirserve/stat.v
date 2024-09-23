module dirserve

import os
import arrays

pub struct File {
pub:
	path    string @[required]
	name    string
	siz     string
	typ     string
	is_dir  bool
	is_link bool
	ext     string
}

fn stat(path string) []File {
	get_file := fn [path] (f string) File {
		filename := os.join_path_single(path, f)
		typ := if os.is_dir(filename) {
			'dir'
		} else if os.is_link(filename) {
			'link'
		} else {
			'file'
		}

		return File{
			path:    filename
			name:    f
			typ:     typ
			siz:     human_bytes(os.file_size(filename))
			is_dir:  os.is_dir(filename)
			is_link: os.is_link(filename)
			ext:     os.file_ext(filename)
		}
	}

	// list all files and convert them to File objects
	stat_files := os.ls(path) or {
		log.error('failed to list files in ${path}')
		[]
	}
	files := stat_files.map(get_file)

	// sort directories first, then files
	dirs_only := files.filter(it.is_dir && !it.is_link)
	files_only := files.filter(!it.is_dir && !it.is_link)
	return arrays.append(dirs_only, files_only)
}

fn filter(files []File, opts ServeOpts) []File {
	filter_fn := fn [opts] (f File) bool {
		return if !opts.recurse && f.typ != 'file' {
			false
		} else if opts.allow_types.len > 0 && f.typ == 'file' && f.ext !in opts.allow_types {
			false
		} else if !opts.show_hidden && f.name[0] == `.` {
			false
		} else {
			true
		}
	}
	return files.filter(filter_fn)
}

fn human_bytes(num u64) string {
	mut n := f64(num)
	mut un := ''
	for unit in ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z'] {
		if n < 1024 {
			un = unit
			break
		}
		n /= 1000
	}
	return '${n:.0}${un}'
}

pub fn list_files(abs_path string, opt ServeOpts) []File {
	files := stat(abs_path)
	return filter(files, opt)
}

module dirserve
import os

pub struct File {
	pub:
	path 		string 			[required]
	name 		string
	siz 		string
	typ 		string
	is_dir 	bool
	is_link bool
	ext 		string
}

fn get_dir_path(path string) string {
	return if path[path.len - 1] == `/` {
		path
	} else {
		path + os.path_separator
	}
}

pub fn stat(path string) []File {
	mut files := []File{}

	stat_files := os.ls(path) or {
		return files
	}
	for f in stat_files {
		filename := get_dir_path(path) + f
		typ := if os.is_dir(filename) {
			'dir'
		} else if os.is_link(filename) {
			'link'
		} else {
			'file'
		}

		files << File {
			path: filename
			name: f
			typ: typ
			siz: human_bytes(os.file_size(filename))
			is_dir: os.is_dir(filename)
			is_link: os.is_link(filename)
			ext: os.file_ext(filename)
		}
	}

	mut sorted := []File{}
	for f in files {
		if f.is_dir && !f.is_link {
			sorted << f
		}
	}
	for f in files {
		if !f.is_dir && !f.is_link {
			sorted << f
		}
	}

	return sorted
}

pub fn filter(files []File, opts ServeOpts) []File {
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

fn mkdir(path string) ! {
	os.mkdir(path) !
}

fn human_bytes(num u64) string {
    mut n := f64(num)
    mut un := ''
    for unit in ["", "K", "M", "G", "T", "P", "E", "Z"] {
        if n < 1024 {
            un = unit
            break
        }
        n /= 1000
    }
    return '${n:.0}$un'
}

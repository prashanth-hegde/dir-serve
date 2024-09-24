module main

import veb
import dirserve
import os

pub struct App {
	opts []dirserve.ServeOpts
}

pub struct Context {
	veb.Context
}

fn main() {
	print_usage_and_exit := fn () {
		prg_name := os.file_name(arguments()[0])
		eprintln('usage: ${prg_name} <config_file_abs_path>')
		exit(1)
	}

	if arguments().len < 2 {
		print_usage_and_exit()
	}

	config_file := arguments()[1]
	if !os.is_file(config_file) {
		eprintln('unable to read config file, please provide correct path')
		print_usage_and_exit()
	}

	opts := dirserve.read_config(config_file)
	if opts.len == 0 {
		eprintln('no shares configured in config file ${config_file}')
		print_usage_and_exit()
	}

	mut app := &App{opts}
	veb.run[App, Context](mut app, 8080)
}

// root returns a json response of all the files present in the directory
// If the path is a file, it will return empty json
@['/']
pub fn (app &App) root() veb.Result {
	relative_path := ctx.query['path'] or { return ctx.redirect('/?path=${app.opts.first().name}') }
	opt := app.opts.opt(relative_path)
	resolved_path := opt.resolve_path(relative_path)
	if os.is_file(resolved_path) && os.file_ext(resolved_path) in veb.mime_types {
		return ctx.file(resolved_path)
	} else if os.is_file(resolved_path) && os.file_size(resolved_path) > 500_000 {
		return ctx.text('either file too large or unknown mime type')
	} else if os.is_file(resolved_path) {
		return ctx.text(os.read_file(resolved_path) or { 'unable to read file contents' })
	}

	// all the variables defined in the template should be defined here
	shares := app.opts.map(it.name)
	upload := opt.upload
	files := dirserve.list_files(resolved_path, opt)
	return $veb.html()
}

@['/upload'; post]
pub fn (mut app App) upload() veb.Result {
	file_data := ctx.files['file'][0]
	path := ctx.form['path']

	if file_data.data.len > 0 && file_data.filename != '' {
		all_shares := app.opts
		opt := all_shares.opt(path)
		resolved_path := os.join_path(opt.resolve_path(path), file_data.filename)
		println('writing new file to ${resolved_path}')
		os.write_file(resolved_path, file_data.data) or {
			eprintln('error writing file ${file_data.filename}')
			return ctx.redirect('/${path}')
		}
	}

	return ctx.redirect('/${path}')
}

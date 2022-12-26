module main
import vweb
import dirserve { File, read_config, ServeOpts, get_options, stat, filter, }
import os

fn main() {
	vweb.run(new_app(), 8080)
}

fn new_app() &App {
  mut app := &App{}
  // makes all static files available.
  app.mount_static_folder_at(os.resource_abs_path('./'), '/')
  return app
}

/* web server setup */
struct App {
  vweb.Context
}

/* endpoints */

['/']
pub fn (mut app App) root() vweb.Result {
    all_shares := dirserve.read_config('config.toml')
    shares := all_shares.map(it.name)
		path := app.query['path'] or {''}
		mut files := []File{}
		mut upload := false

    serve_opt := get_options(all_shares, path) or { return $vweb.html() }
		upload = serve_opt.upload
    resolved_path := serve_opt.resolve_path(path)
		if os.is_file(resolved_path) {
			return if os.file_ext(resolved_path) !in vweb.mime_types && os.file_size(resolved_path) < 500000 {
				app.text(os.read_file(resolved_path) or {'unable to read file contents'})
			} else if os.file_ext(resolved_path) in vweb.mime_types {
				app.file(resolved_path)
			} else {
				app.text('either file too large or unknown mime type')
			}
		}

    files = stat(resolved_path)
		files = filter(files, serve_opt)
    return $vweb.html()
}

['/upload'; post]
pub fn (mut app App) upload() vweb.Result {
	file_data := app.Context.files['file'][0]
	path := app.Context.form['path']

	if file_data.data.len > 0 && file_data.filename != '' {
    all_shares := dirserve.read_config('config.toml')
    serve_opt := get_options(all_shares, path) or { return app.redirect('/$path') }
		resolved_path := os.join_path(serve_opt.resolve_path(path), file_data.filename)
		println('writing new file to $resolved_path')
		os.write_file(resolved_path, file_data.data) or {
			eprintln('error writing file $file_data.filename')
			return app.redirect('/$path')
		}
	}

	return app.redirect('/$path')
}

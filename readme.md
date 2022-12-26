# dir-serve

A simple lightweight program to pretty-serve directories from a given system.

### Features:
* Config driven - see all shares in one place
* Multiple shares
* Pretty html view of files
* Ability to hide or show specific file types
* Ability to upload files to the share

Python has a simple http server as part of http module. However, if you want to share
multiple directories in the system, you need to open multiple shells, navigate to the
respective directories and run the python http server from each of those directories.

But we needed something more configurable. Something that provides a little more control like preventing navigating
through directories, exposing only specific file extensions etc. Hence this repo was born. The app is a single binary,
easy to use and navigate. No external dependency required. The shares is configurable with a simple toml config file.

### Examples:

Sample config file:

#### Basic config:
```toml
[[shares]]
name 		= "Docs"
path 		= "/absolute/path/of/share"
```

#### Enhanced config:
```toml
[[shares]]
name 			= "Docs"
path 			= "/absolute/path/of/share"
upload 		= false										# makes this a read-only share, optional, default=false
recurse 	= true										# enables directory traversal within share, optional, default=false
allow_types = "md,adoc,pdf"					# only exposes specific extensions, comma-separated, optional, default=""
show_hidden = false									# show hidden files (filenames starting with a dot) optional, default=false
```

**Note: If you want to expose multiple shares, just replicate the `[[shares]]` section with a different name and
config**



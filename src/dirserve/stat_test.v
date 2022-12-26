module dirserve

fn test_filter() {
	filenames := [
		'file1',
		'file2.mp4',
		'file3.mkv',
		'file4.txt',
		'dir1',
		'dir2',
		'.hidden',
	]
	files := filenames.map(fn (f string) File {
		return File{
			path: '/tmp/$f',
			name: f,
			ext: if f.split('.').len > 1 { f.split('.')[1] } else { '' }
			typ: if f.contains('dir') {
				'dir'
			} else {
				'file'
			}
		}
	})

	options := [
		ServeOpts{name:'no_recurse', path:'', recurse:false, show_hidden:true},
		ServeOpts{name:'recurse', path:'', recurse:true, show_hidden:true},
		ServeOpts{name:'no_hidden', path:'', recurse:true, show_hidden:false},
		ServeOpts{name:'allowed_types', path:'', recurse:false, allow_types:['mp4','mkv']},
	]
	// same order as options, expected number of files in each one
	expected_files := [
		['file1', 'file2.mp4', 'file3.mkv', 'file4.txt', '.hidden'],
		['file1', 'file2.mp4', 'file3.mkv', 'file4.txt', 'dir1', 'dir2', '.hidden'],
		['file1', 'file2.mp4', 'file3.mkv', 'file4.txt', 'dir1', 'dir2', ],
		['file2.mp4', 'file3.mkv', ],
	]

	for i, test_case in options {
		filtered := filter(files, test_case)
		filtered_filenames := filtered.map(it.name)
		assert filtered_filenames == expected_files[i], test_case.name

	}
}

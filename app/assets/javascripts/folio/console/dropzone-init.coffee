Dropzone.autoDiscover = false;

# images modal dropzone
template = document.querySelector('#image-dropzone-template')
if template
	$('#dropzone-new-image').dropzone
		url: '/console/files'
		maxFilesize: 10 # MB
		resizeMethod: 'crop'
		paramName: 'file[file]'
		thumbnailWidth: 250
		thumbnailHeight: 250
		previewTemplate: template.innerHTML
		addedfile: (file) ->
			return
		thumbnail: (file, dataUrl) ->
			if file.status == 'success'
				$(file.previewElement).find('img').attr('src',dataUrl)
			else
				file.thumbnailUrl = dataUrl
			return file
		params:
			'file[type]': 'Folio::Image',
			'authenticity_token': $("meta[name='csrf-token']").attr('content')
		success: (file, response) ->
			file.previewElement = Dropzone.createElement(@options.previewTemplate)
			$template = $(file.previewElement)
			$template.find('a.card.select-file')
				.addClass('active')
				.data('file-id', response.id)
				.data('file-filesize', response.file_size)
				.data('file-size', response.size)
			if file.thumbnailUrl
				$template.find('img').attr('src', file.thumbnailUrl)

			$('#image-dropzone-template')
				.parent()
				.children('.col-image:last-child')
				.remove()
			$('#image-dropzone-template')
				.after($template)
			return file
		error: (file, message) ->
			$('#dropzone-error').removeClass('hidden')
			$('#dropzone-error .alert').html("#{file.upload.filename}: #{message}")
			return file

# documents modal dropzone
template = document.querySelector('#document-dropzone-template')
if template
	$('#new_document').dropzone
		maxFilesize: 1024 # MB
		paramName: 'file[file]'
		createImageThumbnails: false
		previewTemplate: template.outerHTML
		addedfile: (file) ->
			return file
		success: (file, response) ->
			$template = $(@options.previewTemplate).clone()
			$template.removeClass('hidden template').removeAttr('id')
				.addClass('active')
				.data('file-id', response.id)
				.data('file-filesize', response.file_size)
				.data('file-filename', response.file_name)
			$template.find("[name='file_size']").html(response.file_size)
			$template.find("[name='file_name']").html(response.file_name)
			$('#document-dropzone-template').after($template)
			return file
		error: (file, message) ->
			$('#dropzone-error').removeClass('hidden')
			$('#dropzone-error .alert').html("#{file.upload.filename}: #{message}")
			return file

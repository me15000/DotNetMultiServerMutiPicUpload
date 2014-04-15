function set_upload_status(id, status) {
	$("#" + id).find('.u-status').text(status);
}

function set_cancel(id) {
	swfu.cancelUpload(id);
	if (swfu.getStats().files_queued == 0) {
		$('#btnCancel').addClass('hiddenbtn');
		$('#starupload').addClass('hiddenbtn');
	}
	$("#" + id).fadeOut(400);
	setTimeout(function(){$("#" + id).remove();},500);
	return false;
}

$('.u-edit').live('click', function() {
	var edit_text = $(this).text();
	if ( edit_text == 'Edit' ) {
		$(this).text('Hide');
		$(this).next().slideDown(300);
	} else {
		$(this).text('Edit');
		$(this).next().slideUp(300);
	}
});
/*
	<div id="fileid" class="u-wrap">
		<div class="u-inside">
			<a class="u-cancel" onclick="set_cancel(fileid)" href="javascript:void(0)">Cancel</a>
			<div class="u-name"></div>
			<div class="u-status"></div>
			<div class="u-bar"></div>
		</div>
	</div>
*/
function fileQueued(file) {
	if ( $('#fsUploadProgress').length ) {
		$('#fsUploadProgress').append('<div id="' + file.id + '" class="u-wrap"><div class="u-inside"><a class="u-cancel"  onclick="set_cancel(\'' + file.id + '\')" href="javascript:void(0)">Cancel</a><div class="u-name">' + file.name + '</div><div class="u-status">Pending...</div><div class="u-bar"></div></div></div>');
	}
	$('#btnCancel').removeClass('hiddenbtn');
	$('#starupload').removeClass('hiddenbtn');
}

function fileQueueError(file, errorCode, message) {
	try {
		if (errorCode === SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED) {
			alert("You have attempted to queue too many files.\n" + (message === 0 ? "You have reached the upload limit." : "You may select " + (message > 1 ? "up to " + message + " files." : "one file.")));
			return;
		}

		switch (errorCode) {
		case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
			set_upload_status(file.id, "File is too big.");
			this.debug("Error Code: File too big, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
			set_upload_status(file.id, "Cannot upload Zero Byte files.");
			this.debug("Error Code: Zero byte file, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
			set_upload_status(file.id, "Invalid File Type.");
			this.debug("Error Code: Invalid File Type, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		default:
			if (file !== null) {
				set_upload_status(file.id, "Unhandled Error");
			}
			this.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		}
	} catch (ex) {
        this.debug(ex);
    }
}

function fileDialogComplete(numFilesSelected, numFilesQueued) {
	if (numFilesSelected > 0) {
		$('#btnCancel').removeClass('hiddenbtn');
		$('#finishbtn').addClass('hiddenbtn');
	}
}

function uploadStart(file) {
	$('#starupload').addClass('hiddenbtn');
	set_upload_status(file.id, 'Uploading...');
	return true;
}

function uploadProgress(file, bytesLoaded, bytesTotal) {
	var percent = Math.ceil((bytesLoaded / bytesTotal) * 100);
	$('#' + file.id).find('.u-bar').animate({ 
		width: percent + "%",
	}, 200 );
	set_upload_status(file.id, percent + '% (' + bytesLoaded + '/' + bytesTotal + ' Bytes)');
}

function uploadSuccess(file, serverData) {
    if (serverData) {

        var json = eval('(' + serverData + ')');
        if (json && json.resp) {

            var data = json.resp;
            if (data.success) {
                document.getElementById('urlPanel').value += data.link + '\n';
                $('#' + file.id).find('.u-cancel').hide();
                $('#' + file.id).find('.u-bar').remove();
                $('#' + file.id).find('.u-inside').append('<a class="u-edit" href="javascript:void(0)">Edit</a>');
                $('#' + file.id).find('.u-inside').append('<div class="u-photo-edit"><img src="' + data.link + '" /></div>');
                set_upload_status(file.id, '上传成功.');
            }
        }
    }
}

function uploadError(file, errorCode, message) {
	try {
		$('#' + file.id).find('.u-bar').remove();
		switch (errorCode) {
		case SWFUpload.UPLOAD_ERROR.HTTP_ERROR:
			set_upload_status(file.id, "Upload Error: " + message);
			this.debug("Error Code: HTTP Error, File name: " + file.name + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.UPLOAD_FAILED:
			set_upload_status(file.id, "Upload Failed.");
			this.debug("Error Code: Upload Failed, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.IO_ERROR:
			set_upload_status(file.id, "Server (IO) Error");
			this.debug("Error Code: IO Error, File name: " + file.name + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.SECURITY_ERROR:
			set_upload_status(file.id, "Security Error");
			this.debug("Error Code: Security Error, File name: " + file.name + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
			set_upload_status(file.id, "Upload limit exceeded.");
			this.debug("Error Code: Upload Limit Exceeded, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.FILE_VALIDATION_FAILED:
			set_upload_status(file.id, "Failed Validation.  Upload skipped.");
			this.debug("Error Code: File Validation Failed, File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
			// If there aren't any files left (they were all cancelled) disable the cancel button
			if (this.getStats().files_queued === 0) {
				$('#btnCancel').addClass('hiddenbtn');
			}
			set_upload_status(file.id, "Cancelled");
			//progress.setCancelled();
			set_cancel(file.id);
			break;
		case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
			set_upload_status(file.id, "Stopped");
			break;
		default:
			set_upload_status(file.id, "Unhandled Error: " + errorCode);
			this.debug("Error Code: " + errorCode + ", File name: " + file.name + ", File size: " + file.size + ", Message: " + message);
			break;
		}
	} catch (ex) {
        this.debug(ex);
    }
}

function uploadComplete(file) {
	if (this.getStats().files_queued === 0) {
		$('#btnCancel').addClass('hiddenbtn');        
        setTextSelected(document.getElementById("urlPanel"));
	}
}

function queueComplete(numFilesUploaded) {
	$('#divStatus').text(numFilesUploaded + " file" + (numFilesUploaded === 1 ? "" : "s") + " uploaded.");
	$('#finishbtn').removeClass('hiddenbtn');
}
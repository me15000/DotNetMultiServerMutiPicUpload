<%@ Page Language="C#" %>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>mutiupload</title>
    <link href="static/swfupload/style.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <div id="content" style="margin-top: 20px;">
        <div id="uploader">


            <div id="swfuploader" class="upload" style="margin-top: 32px;">
                <!--[if lte IE 7]>
			<p>你好，由于你的浏览器版本过低（IE 7 及以下的浏览器），所以无法使用 FLASH 上传。</p>
			<![endif]-->

                <div id="swfuploadbtn">
                    <span id="spanButtonPlaceHolder"></span>
                    <input id="starupload" class="button white medium hiddenbtn" type="button" onclick="swfu.startUpload();"
                        value="上传这些文件" />
                    <a id="btnCancel" class="hiddenbtn" href="javascript:void(0)" onclick="swfu.cancelQueue();">
                        <span>取消所有上传</span></a>
                </div>
                <div class="fieldset flash" id="fsUploadProgress">
                </div>
                <p>
                    <span id="divStatus"></span>
                </p>
            </div>
            <!-- #swfuploader -->



            <div>图片列表</div>
            <div style="margin-top: 24px;">
                <textarea rows="40" cols="132" style="font-size: 12px;" id="urlPanel"></textarea>
            </div>
        </div>
        <!-- #uploader -->




    </div>



















</body>
</html>
<script src="static/script/jquery-1.6.2.js" type="text/javascript"></script>
<script src="static/swfupload/swfupload.js" type="text/javascript"></script>
<script src="static/swfupload/swfupload.queue.js" type="text/javascript"></script>
<script src="static/swfupload/handlers.js" type="text/javascript"></script>

<script type="text/javascript">
    function setTextSelected(inputDom, startIndex, endIndex) {
        startIndex = startIndex || 0;
        endIndex = endIndex || inputDom.value.length;
        if (inputDom.setSelectionRange) {
            inputDom.setSelectionRange(startIndex, endIndex);
        }
        else if (inputDom.createTextRange) //IE 
        {
            var range = inputDom.createTextRange();
            range.collapse(true);
            range.moveStart('character', startIndex);
            range.moveEnd('character', endIndex - startIndex - 1);
            range.select();
        }
        inputDom.focus();
    }



    var swfu;
    window.onload = function () {
        var settings = {
            flash_url: "static/swfupload/swfupload.swf",
            upload_url: "../do.ashx?action=upload&format=json&SecurityKey=<%=ConfigurationManager.AppSettings["SecurityKey"]%>",
            post_params: {
                "SESSIONID": "<%=Session.SessionID%>"
            },
            file_size_limit: "100 MB",
            file_types: "*.jpg;*.gif;*.png;*.bmp;*.jpeg",
            file_types_description: "Pictures",
            file_upload_limit: 10000,
            file_queue_limit: 0,
            custom_settings: {
                progressTarget: "fsUploadProgress",
                cancelButtonId: "btnCancel"
            },
            debug: false,

            // 按钮设置
            button_image_url: "static/swfupload/images/uploadbtn.png",
            button_width: "116",
            button_height: "28",
            button_placeholder_id: "spanButtonPlaceHolder",
            button_cursor: SWFUpload.CURSOR.HAND,

            // The event handler functions are defined in handlers.js
            file_queued_handler: fileQueued,
            file_queue_error_handler: fileQueueError,
            file_dialog_complete_handler: fileDialogComplete,
            upload_start_handler: uploadStart,
            upload_progress_handler: uploadProgress,
            upload_error_handler: uploadError,
            upload_success_handler: uploadSuccess,
            upload_complete_handler: uploadComplete,
            // Queue plugin event
            queue_complete_handler: queueComplete
        };
        swfu = new SWFUpload(settings);
    };

function select_upload(sid) {
    var btn = $('#b-' + sid);
    var set = $('#' + sid);
    $('#u-way a').removeClass('selected');
    btn.addClass('selected');
    $('.upload').hide();
    set.slideDown(400);
}
select_upload('swfuploader');
</script>

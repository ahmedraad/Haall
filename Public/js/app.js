function likeClick(element) {
  var post_id = element.value;
  $.post("/like_post", {"post_id": post_id, "status": true}, function(data) {
    if (data.data) {
      if (data.data.status) {
        $('#likebutton_' + post_id).css('color', '#007bff')
        $('#unlikebutton_' + post_id).css('color', '#737373')
      } else {
        $('#likebutton_' + post_id).css('color', '#737373')
      }
    } else {
      console.log("here");
      $('#likebutton_' + post_id).css('color', '#737373')
      $('#unlikebutton_' + post_id).css('color', '#737373')
    }
    $('#likebutton_' + post_id).html('<i class="fa fa-thumbs-up" aria-hidden="true">' + ' ' + data.post_likes + '</i>');
    $('#unlikebutton_' + post_id).html('<i class="fa fa-thumbs-down" aria-hidden="true">' + ' ' + data.post_dislikes + '</i>');
    }, 'json');
}

function unlikeClick(element) {
  var post_id = element.value;
  $.post("/like_post", {"post_id": post_id, "status": false}, function(data) {
    if (data.data) {
      if (!data.data.status) {
        $('#unlikebutton_' + post_id).css('color', '#F71735')
        $('#likebutton_' + post_id).css('color', '#737373')
      } else {
        $('#unlikebutton_' + post_id).css('color', '#737373')
      }
    } else {
      $('#likebutton_' + post_id).css('color', '#737373')
      $('#unlikebutton_' + post_id).css('color', '#737373')
    }
    $('#likebutton_' + post_id).html('<i class="fa fa-thumbs-up" aria-hidden="true">' + ' ' + data.post_likes + '</i>');
    $('#unlikebutton_' + post_id).html('<i class="fa fa-thumbs-down" aria-hidden="true">' + ' ' + data.post_dislikes + '</i>');
    }, 'json');
}


function singlePostlikeClick(element) {
  var post_id = element.value;
  $.post("/like_post", {"post_id": post_id, "status": true}, function(data) {
    if (data.data) {
      if (data.data.status) {
        $('#likebutton_' + post_id).css('color', '#007bff')
        $('#unlikebutton_' + post_id).css('color', '#737373')
      } else {
        $('#likebutton_' + post_id).css('color', '#737373')
      }
    } else {
      $('#likebutton_' + post_id).css('color', '#737373')
      $('#unlikebutton_' + post_id).css('color', '#737373')
    }
    $('#likebutton_' + post_id).html('<i class="fa fa-thumbs-up" aria-hidden="true"></i>');
    $('#unlikebutton_' + post_id).html('<i class="fa fa-thumbs-down" aria-hidden="true"></i>');
    }, 'json');
}

function singlePostunlikeClick(element) {
  var post_id = element.value;
  $.post("/like_post", {"post_id": post_id, "status": false}, function(data) {
    if (data.data) {
      if (!data.data.status) {
        $('#unlikebutton_' + post_id).css('color', '#F71735')
        $('#likebutton_' + post_id).css('color', '#737373')
      } else {
        $('#unlikebutton_' + post_id).css('color', '#737373')
      }
    } else {
      $('#likebutton_' + post_id).css('color', '#737373')
      $('#unlikebutton_' + post_id).css('color', '#737373')
    }
    $('#likebutton_' + post_id).html('<i class="fa fa-thumbs-up" aria-hidden="true"></i>');
    $('#unlikebutton_' + post_id).html('<i class="fa fa-thumbs-down" aria-hidden="true"></i>');
    }, 'json');
}


$("#new-post-button").click(function(){
      data_array = $("#add-post-form").serializeArray();
      var data = {};
      $(data_array).each(function(index, obj){
          data[obj.name] = obj.value;
      });

      $.ajax({
        url:"/add",
        method:"POST",
        data: data,
        success:function(response) {
         if (response.status) {
           $('#addModal').modal('hide');
           toastr.success(response.msg);
         } else {
           toastr.error(response.msg);
         }
       },
       error:function(){
        toastr.error("some error");
       }
    });
});

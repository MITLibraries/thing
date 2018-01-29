function markDownloaded() {
  function alertFail(target) {
    target.append("<div class='alert alert-banner error'>We're sorry; this thesis could not be marked as downloaded.</div>");
  }

  $(document).ready(function() {
    $("form").on("ajax:success", function (event) {
      // Find actionable data.
      var saved = event.detail[0].saved;
      var thesis_id = event.detail[0].id.toString();
      var target = $("div[data-id=thesis_" + thesis_id + "]");

      // Communicate status to users.
      if ( saved ) {
        target.attr('class', 'panel panel-success');
        target.find('form').replaceWith("<div>&#10004; Marked as downloaded</div>");
        target.find('span.text-info').attr('class', 'text-success').text('downloaded');
      } else {
        alertFail(target.children('.panel-body'));
      }

    }).on("ajax:error", function (data) {
      var target = $("form input:focus").parents('div.panel-body');
      alertFail(target);
    });
  });
}

function updateStatus() {
  function alertFail(target, verb) {
    target.append("<div class='alert alert-banner error'>We're sorry; this thesis could not be marked as " + verb + ".</div>");
  }

  function updateStatusSpan(target, verb) {
    if (verb == 'withdrawn') {
      var status = 'text-danger';
    } else if (verb == 'downloaded') {
      var status = 'text-success';
    }

    target.find('span.thesis-status'
      // Remove all classes,=; add back in the one we need to find the div
      ).attr('class', 'thesis-status'
      // Update with styling and text
      ).addClass(status
      ).text(verb);
  }

  $(document).ready(function() {
    $("form").on("ajax:success", function (event) {
      // Find actionable data.
      var verb = $(this).attr('class');
      var saved = event.detail[0].saved;
      var thesis_id = event.detail[0].id.toString();
      var target = $("div[data-id=thesis_" + thesis_id + "]");

      // Communicate status to users.
      if ( saved ) {
        target.attr('class', 'panel panel-success');
        $(this).replaceWith("<div>&#10004; Marked as " + verb + "</div>");
        updateStatusSpan(target, verb);
      } else {
        alertFail(target.children('.panel-body'), verb);
      }

    }).on("ajax:error", function (data) {
      var active_element = $("form input:focus");
      var target = active_element.parents('div.panel-body');
      var verb = active_element.parent('form').attr('class');
      alertFail(target, verb);
    });
  });
}

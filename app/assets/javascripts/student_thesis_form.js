// This is the shared javascript for the new and edit thesis forms that are
// used by students.

// Hide/show license field based on copyright answer
function conditionalLicenseField() {
  var value = $("select#thesis_copyright_id option:selected").text();
  if ('I hold copyright' == value) {
    $("div.thesis_license").show();
  } else {
    $("div.thesis_license").hide();
    $("select#thesis_license_id")[0].value = "";
  }
};

// Hide/show "remove this supervisor" link if only one
// field is present (one value is required)
function hideOnlySupervisorLink() {
  if ($("a.remove_fields").length == 1) {
    $("a.remove_fields").addClass("only");
  } else {
    $("a.remove_fields").removeClass("only")
  }
}

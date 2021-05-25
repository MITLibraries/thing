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
function hideOnlyLink(group) {
  var visible_fields = visibleFields(group);
  console.log('I see the following visible ' + group + ' fields:');
  console.log(visible_fields);
  if ( visible_fields.length === 1 ) {
    $("div." + group + " a.remove_fields").addClass("only");
  } else {
    $("div." + group + " a.remove_fields").removeClass("only")
  }
}

// Sets the form's focus on the first visible supervisor
// field. Called after one is removed, to ensure focus
// is always defined.
function focusOnFirstVisibleField(group) {
  var visible_fields = visibleFields(group);
  $( $(visible_fields)[0] ).find("input[type=text]").focus();
}

// Shared function to count how many supervisor fields
// are visible. This is needed because, when editing a
// thesis record, the "remove this supervisor" link does
// not actually remove the field from the DOM - so you
// need to filter the list of fields by which have been
// made invisible.
//
// This is called by both the focus and hideOnly functions
// above.
function visibleFields(group) {
  return $('div.' + group + '.nested-fields').filter(function() {
    if ( $(this).attr('style')==='display: none;') {
      return false;
    }
    return true;
  });
}

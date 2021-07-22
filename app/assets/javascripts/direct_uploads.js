// direct_uploads.js
/* original source:
   http://edgeguides.rubyonrails.org/active_storage_overview.html#example
   listener targets updated according to:
   https://github.com/marinosoftware/active_storage_drag_and_drop#javascript-events */

var storageErrorDetected = false;
var completedInTransfer = 0;
var filesInTransfer = 0;

addEventListener("dnd-uploads:start", event => {
  location.hash = "direct-upload-panel"
  document.getElementById("direct-upload-panel").insertAdjacentHTML("afterbegin", `
    <div class="direct-upload__summary">
      <div class="alert alert-banner" aria-live="polite">
        <p>Upload in progress: <span id="direct-upload-status"></span> <strong>Do not close this browser window during transfer.</strong></p>
      </div>
    </div>
  `)
  document.getElementById("direct-upload-status").innerHTML = `${completedInTransfer} of ${filesInTransfer} files have been transferred.`
})

addEventListener("dnd-upload:initialize", event => {
  const { target, detail } = event
  const { id, file } = detail
  filesInTransfer++
  document.getElementById("direct-upload-panel").insertAdjacentHTML("beforeend", `
    <div id="direct-upload-${id}" class="direct-upload direct-upload--pending alert alert-banner">
      <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
      <p>
        <i id="direct-upload-icon-${id}" class="fa fa-lg"></i>
        <span class="direct-upload__filename">${file.name}</span>
      </p>
    </div>
  `)
})

addEventListener("dnd-upload:start", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.remove("direct-upload--pending")
})

addEventListener("dnd-upload:progress", event => {
  const { id, progress } = event.detail
  const progressElement = document.getElementById(`direct-upload-progress-${id}`)
  progressElement.style.width = `${progress}%`
  progressElement.style.background = "#008700"
})

addEventListener("dnd-upload:error", event => {
  event.preventDefault()
  const { id, error } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  Raven.captureException('ActiveStorage Direct Upload Failed.')
  storageErrorDetected = true
  element.classList.add("direct-upload--error")
  element.setAttribute("title", error)
  element.insertAdjacentHTML("afterend", `
    <div id="direct-upload-${id}" class="alert alert-banner error">
      Something went wrong on our end and we weren't able to upload your file. You can try submitting again or contact etheses-admin@mit.edu for assistance.
    </div>
  `)
})

addEventListener("dnd-upload:end", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--complete")
  element.classList.add("success")
  const icon = document.getElementById(`direct-upload-icon-${id}`)
  icon.classList.add("fa-check-circle")
  completedInTransfer++
  document.getElementById("direct-upload-status").innerHTML = `${completedInTransfer} of ${filesInTransfer} files have been transferred.`
})

addEventListener("dnd-uploads:end", event => {
  // Workaround for https://github.com/rails/rails/issues/31860
  // only do the submit hack if we didn't detect an error or the user won't see
  // our in-app messages and will instead see a throw exception.
  if (storageErrorDetected == false) {
    event.target.submit()
  }
})

// direct_uploads.js
/* original source:
   http://edgeguides.rubyonrails.org/active_storage_overview.html#example */

var storageErrorDetected = false;

addEventListener("direct-upload:initialize", event => {
  const { target, detail } = event
  const { id, file } = detail
  target.insertAdjacentHTML("beforebegin", `
    <div id="direct-upload-${id}" class="direct-upload direct-upload--pending">
      <div id="direct-upload-progress-${id}" class="direct-upload__progress" style="width: 0%"></div>
      <span class="direct-upload__filename">${file.name}</span>
    </div>
  `)
})

addEventListener("direct-upload:start", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.remove("direct-upload--pending")
})

addEventListener("direct-upload:progress", event => {
  const { id, progress } = event.detail
  const progressElement = document.getElementById(`direct-upload-progress-${id}`)
  progressElement.style.width = `${progress}%`
})

addEventListener("direct-upload:error", event => {
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

addEventListener("direct-upload:end", event => {
  const { id } = event.detail
  const element = document.getElementById(`direct-upload-${id}`)
  element.classList.add("direct-upload--complete")
})

addEventListener("direct-uploads:end", event => {
  // Workaround for https://github.com/rails/rails/issues/31860
  // only do the submit hack if we didn't detect an error or the user won't see
  // our in-app messages and will instead see a throw exception.
  if (storageErrorDetected == false) {
    event.target.submit()
  }
})

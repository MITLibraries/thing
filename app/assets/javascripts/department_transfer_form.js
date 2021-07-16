function localFileSizeSI (bytes) {
  let e = Math.log(bytes) / Math.log(1000) | 0
  const size = (bytes / Math.pow(1000, e) + 0.5) | 0
  return size + (e ? 'kMGTPEZY'[--e] + 'B' : ' Bytes')
};

window.ActiveStorageDragAndDrop.paintUploadIcon = function (iconContainer, id, file, complete) {
  const uploadStatus = (complete ? 'complete' : 'pending')
  const progress = (complete ? 100 : 0)
  iconContainer.insertAdjacentHTML('beforeend', `
  <div data-direct-upload-id="${id}">
    <div class="direct-upload direct-upload--${uploadStatus}">
      <div class="direct-upload__progress" style="width: ${progress}%"></div>
      <span class="direct-upload__filename">${file.name}</span>
      <span class="direct-upload__filesize">${localFileSizeSI(file.size)}</span>
    </div>&nbsp;
    <a href='remove' class='direct-upload__remove'>(Remove this file)</a>
  </div>
  `)
};
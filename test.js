const perm = require('./index')

for (let mediaType of ['camera', 'microphone']) {
  let access = perm.getMediaAccessStatus(mediaType)
  if (access == 'not-determined') {
    perm.askForMediaAccess(mediaType, (granted) => {
      console.log(mediaType + ' askForMediaAccess result:', granted)
    })
  } else {
    console.log(`${mediaType} access status: ${access}`)
  }
}

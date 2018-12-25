const bin = require('./build/Release/mojave-permissions')

module.exports = {
  /**
   * @param {String} mediaType
   * @return {String}
   */
  getMediaAccessStatus(mediaType) {
    return bin.getMediaAccessStatus(mediaType)
  },

  /**
   * @param {String} mediaType
   * @param {Function} callback
   */
  askForMediaAccess(mediaType, callback) {
    return bin.askForMediaAccess(mediaType, callback)
  }
}

# mojave-permissions

This is native nodejs module that implements access to `getMediaAccessStatus` and `askForMediaAccess` functions introduced in macOS Mojave 10.14.

## Building

```
node-gyp configure
node-gyp build
```

And you can check if it works:
```
node test.js
```

Tested on macOS 10.14 and 10.13 with nodejs 11.3.0 and Electron 1.8.8 (node 8.2.1).

## API

### getMediaAccessStatus(mediaType)

**mediaType** is a string and can be `microphone` or `camera`

Returns one of the following values: `not-determined`, `restricted`, `denied` or `granted`

### askForMediaAccess(mediaType, callback)

Asks user for media access and returns user choice to the callback. Example:

```
mojavePermissions.askForMediaAccess('camera', (granted) => {
  if (!granted) {
    // user has denied access to camera
  }
})
```

## License

I don't care; you can use it however you want.

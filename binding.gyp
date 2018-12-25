{
  "targets": [
    {
      "target_name": "mojave-permissions",
      'conditions': [
        ['OS=="mac"', {
          'sources': [
            'index.mm'
          ],
          'xcode_settings': {
            'CLANG_CXX_LIBRARY': 'libc++',
            'MACOSX_DEPLOYMENT_TARGET': '10.14',
            'OTHER_CFLAGS': [
                '-ObjC++'
            ]
          }
        }]
      ],
      "libraries": [ "-framework AVFoundation" ]
    }
  ]
}

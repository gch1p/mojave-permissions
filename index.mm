#include <node.h>
#include <v8.h>
#include <stdio.h>
#include <unistd.h>
#include <uv.h>
#include <string>

#import <AVFoundation/AVFoundation.h>

using namespace v8;

AVMediaType ParseMediaType(const std::string& media_type) {
  if (media_type == "camera") {
    return AVMediaTypeVideo;
  } else if (media_type == "microphone") {
    return AVMediaTypeAudio;
  } else {
    return nil;
  }
}

std::string ConvertAuthorizationStatus(AVAuthorizationStatus status) {
  switch (status) {
    case AVAuthorizationStatusNotDetermined:
      return "not-determined";
    case AVAuthorizationStatusRestricted:
      return "restricted";
    case AVAuthorizationStatusDenied:
      return "denied";
    case AVAuthorizationStatusAuthorized:
      return "granted";
    default:
      return "unknown";
  }
}

bool isMojave() {
    NSOperatingSystemVersion minimumSupportedOSVersion = { .majorVersion = 10, .minorVersion = 14, .patchVersion = 0 };
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumSupportedOSVersion];
}

struct Baton {
    uv_work_t request;
    Persistent<Function> callback;
    AVMediaType type;
    bool hasResponse;
    bool granted;
    Baton() : hasResponse(0), granted(0) {}
};

// called by libuv worker in separate thread
static void DelayAsync(uv_work_t *req) {
    Baton *baton = static_cast<Baton *>(req->data);
    [AVCaptureDevice requestAccessForMediaType:baton->type
                               completionHandler:^(BOOL granted) {
                                    baton->granted = granted;
                                    baton->hasResponse = true;
                               }];

    while (!baton->hasResponse) {
        usleep(100000);
    }
}

// called by libuv in event loop when async function completes
static void DelayAsyncAfter(uv_work_t *req,int status) {
    Isolate * isolate = Isolate::GetCurrent();
    HandleScope scope(isolate);

    Baton *baton = static_cast<Baton *>(req->data);

    Local<Value> argv[1] = {
        v8::Boolean::New(isolate, baton->granted)
    };

    Local<Function>::New(isolate, baton->callback)->Call(isolate->GetCurrentContext()->Global(), 1, argv);
    baton->callback.Reset();

    delete baton;
}

void AskForMediaAccess(const v8::FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = Isolate::GetCurrent();
    HandleScope scope(isolate);

    if (!args[0]->IsString()) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "argument 0 must be string")));
        return;
    }

    if (!args[1]->IsFunction()) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "argument 1 must be function")));
        return;
    }

    String::Utf8Value mediaTypeValue(args[0]);
    std::string mediaType(*mediaTypeValue);

    Local<Function> cbFunc = Local<Function>::Cast(args[1]);

    if (auto type = ParseMediaType(mediaType)) {
        if (isMojave()) {
            Baton *baton = new Baton;
            baton->type = type;
            baton->callback.Reset(isolate, cbFunc);
            baton->request.data = baton;

            // queue the async function to the event loop
            // the uv default loop is the node.js event loop
            uv_queue_work(uv_default_loop(), &baton->request, DelayAsync, DelayAsyncAfter);
        } else {
            Local<Value> argv[1] = { v8::True(isolate) };
            cbFunc->Call(isolate->GetCurrentContext()->Global(), 1, argv);
        }
    } else {
        isolate->ThrowException(Exception::TypeError(
        String::NewFromUtf8(isolate, "invalid media type")));
    }

    args.GetReturnValue().Set(Undefined(isolate));
}

void GetMediaAccessStatus(const v8::FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = Isolate::GetCurrent();
    HandleScope scope(isolate);

    if (!args[0]->IsString()) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "argument 0 must be string")));
        return;
    }

    String::Utf8Value mediaTypeValue(args[0]);
    std::string mediaType(*mediaTypeValue);

    if (auto type = ParseMediaType(mediaType)) {
        if (isMojave()) {
            args.GetReturnValue().Set(String::NewFromUtf8(isolate, ConvertAuthorizationStatus(
                    [AVCaptureDevice authorizationStatusForMediaType:type]).c_str()));
        } else {
            // access always allowed pre-10.14 Mojave
            args.GetReturnValue().Set(String::NewFromUtf8(isolate, ConvertAuthorizationStatus(AVAuthorizationStatusAuthorized).c_str()));
        }
    } else {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "invalid media type")));
    }
}

void Init(Local<Object> exports) {
    NODE_SET_METHOD(exports, "getMediaAccessStatus", GetMediaAccessStatus);
    NODE_SET_METHOD(exports, "askForMediaAccess", AskForMediaAccess);
}

NODE_MODULE(mojavepermissions, Init)

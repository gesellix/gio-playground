//go:build ios

package playground

/*
#cgo CFLAGS: -fobjc-arc -fmodules
#cgo LDFLAGS: -framework UIKit

#include <stdlib.h>

void observeScenes(void);
void disconnectScenes(void);
int hasInfoKey(const char *key);
char *infoString(const char *key);
int hasResource(const char *name, const char *ext);
*/
import "C"

import (
	"strings"
	"unsafe"
)

const canDisconnectScene = true

func initPlatform() {
	C.observeScenes()
	k := C.CString("UIApplicationSceneManifest")
	defer C.free(unsafe.Pointer(k))
	n, ext := C.CString("PrivacyInfo"), C.CString("xcprivacy")
	defer C.free(unsafe.Pointer(n))
	defer C.free(unsafe.Pointer(ext))
	events.add("Info.plist has UIApplicationSceneManifest: " + yesNo(C.hasInfoKey(k) != 0))
	for _, key := range []string{"MinimumOSVersion", "CFBundleShortVersionString", "CFBundleExecutable", "PlaygroundPlatformFile"} {
		events.add("Info.plist " + key + ": " + infoString(key))
	}
	events.add("bundle has PrivacyInfo.xcprivacy: " + yesNo(C.hasResource(n, ext) != 0))
}

// disconnectScene asks UIKit to destroy the session of every connected
// scene, which disconnects it. Opening the app again connects a new one.
func disconnectScene() { C.disconnectScenes() }

//export playgroundSceneEvent
func playgroundSceneEvent(s *C.char) {
	events.add("UIScene: " + strings.TrimSpace(C.GoString(s)))
}

// infoString returns the string value of key in the Info.plist, or "not
// set".
func infoString(key string) string {
	k := C.CString(key)
	defer C.free(unsafe.Pointer(k))
	v := C.infoString(k)
	if v == nil {
		return "not set"
	}
	defer C.free(unsafe.Pointer(v))
	return C.GoString(v)
}

func yesNo(b bool) string {
	if b {
		return "yes"
	}
	return "no"
}

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
	mk := C.CString("MinimumOSVersion")
	defer C.free(unsafe.Pointer(mk))
	min := "not set"
	if v := C.infoString(mk); v != nil {
		min = C.GoString(v)
		C.free(unsafe.Pointer(v))
	}
	events.add("Info.plist MinimumOSVersion: " + min)
	events.add("bundle has PrivacyInfo.xcprivacy: " + yesNo(C.hasResource(n, ext) != 0))
}

// disconnectScene asks UIKit to destroy the session of every connected
// scene, which disconnects it. Opening the app again connects a new one.
func disconnectScene() { C.disconnectScenes() }

//export playgroundSceneEvent
func playgroundSceneEvent(s *C.char) {
	events.add("UIScene: " + strings.TrimSpace(C.GoString(s)))
}

func yesNo(b bool) string {
	if b {
		return "yes"
	}
	return "no"
}

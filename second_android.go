package playground

import (
	"errors"

	"gioui.org/app"
	"git.wow.st/gmp/jni"
)

//go:generate javac --release 8 -classpath $ANDROID_HOME/platforms/android-36/android.jar -d $TMPDIR/playground_second/classes SecondActivity.java
//go:generate jar cf second_android.jar -C $TMPDIR/playground_second/classes .

const canStartSecondActivity = true

// startSecondActivity opens SecondActivity (SecondActivity.java) from view,
// the View of the last app.AndroidViewEvent.
func startSecondActivity(view uintptr) error {
	if view == 0 {
		return errors.New("no view")
	}
	return jni.Do(jni.JVMFor(app.JavaVM()), func(env jni.Env) error {
		class, err := jni.LoadClass(env, jni.ClassLoaderFor(env, jni.Object(app.AppContext())), "com/github/gesellix/gioplayground/SecondActivity")
		if err != nil {
			return err
		}
		start := jni.GetStaticMethodID(env, class, "start", "(Landroid/view/View;)V")
		return jni.CallStaticVoidMethod(env, class, start, jni.Value(view))
	})
}

// androidView returns the View of e, or 0.
func androidView(e app.ViewEvent) uintptr {
	if e, ok := e.(app.AndroidViewEvent); ok {
		return e.View
	}
	return 0
}

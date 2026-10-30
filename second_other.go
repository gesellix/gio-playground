//go:build !android

package playground

import (
	"errors"

	"gioui.org/app"
)

const canStartSecondActivity = false

func startSecondActivity(uintptr) error { return errors.New("only on Android") }

func androidView(app.ViewEvent) uintptr { return 0 }

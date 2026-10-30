// SPDX-License-Identifier: Unlicense OR MIT

package com.github.gesellix.gioplayground;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

// SecondActivity is a plain activity of the app itself, without Gio. While
// it is in front of GioActivity the process is still visible, so Gio should
// report no SuspendEvent; leaving the app from here should.
public final class SecondActivity extends Activity {
	private static final String TAG = "GioPlayground";

	// start opens the activity from the Gio view. Builds whose manifest does
	// not declare it (GIO=upstream) only log that.
	public static void start(View view) {
		Context ctx = view.getContext();
		try {
			ctx.startActivity(new Intent(ctx, SecondActivity.class));
		} catch (ActivityNotFoundException e) {
			Log.w(TAG, "SecondActivity is not declared in this build's manifest", e);
		}
	}

	@Override protected void onCreate(Bundle state) {
		super.onCreate(state);
		Log.i(TAG, "SecondActivity onCreate");
		TextView text = new TextView(this);
		text.setText("A second activity of the app, without Gio. Close it, or leave the app from here (home, screen off), then go back to the event log.");
		text.setTextSize(18);
		Button close = new Button(this);
		close.setText("Close");
		close.setOnClickListener(v -> finish());
		LinearLayout layout = new LinearLayout(this);
		layout.setOrientation(LinearLayout.VERTICAL);
		layout.setPadding(48, 160, 48, 48);
		layout.addView(text);
		layout.addView(close);
		setContentView(layout);
	}

	@Override protected void onStart() {
		super.onStart();
		Log.i(TAG, "SecondActivity onStart");
	}

	@Override protected void onStop() {
		super.onStop();
		Log.i(TAG, "SecondActivity onStop");
	}
}

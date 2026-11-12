package com.example.eyes_school

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // N-24: in `eyesschool://reset?token=…` the target is the URI *host*, and Flutter only
    // forwards the path (empty here), so the router never saw it and the link opened the
    // login. The intent is turned into the app route before Flutter reads it.
    override fun getInitialRoute(): String? = resetRoute(intent) ?: super.getInitialRoute()

    override fun onNewIntent(intent: Intent) {
        val route = resetRoute(intent)
        if (route != null) {
            setIntent(intent)
            flutterEngine?.navigationChannel?.pushRouteInformation(route)
            return
        }
        super.onNewIntent(intent)
    }

    private fun resetRoute(intent: Intent?): String? {
        val data: Uri = intent?.data ?: return null
        if (data.scheme != "eyesschool" || data.host != "reset") return null
        val token = data.getQueryParameter("token") ?: return "/reset-password"
        return "/reset-password?token=" + Uri.encode(token)
    }
}

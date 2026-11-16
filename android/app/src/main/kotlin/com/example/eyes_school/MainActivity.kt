package com.example.eyes_school

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // CP-ACE-088: «Activar» in the profile opens this app's notification settings.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "eyesschool/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationSettings") {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

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

package com.carriez.flutter_hbb

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * Έλεγχος έκδοσης στο notify. Νεότερη έκδοση ανοίγει την εφαρμογή
 * για υποχρεωτική εγκατάσταση.
 */
object FloantaUpdate {
    private const val logTag = "FloantaUpdate"
    private const val manifestUrl = "https://notify.eshopservices.gr/apis/software/floanta_rustdesk"
    private const val intervalMs = 10 * 60 * 1000L
    private const val firstDelayMs = 20_000L
    private val handler = Handler(Looper.getMainLooper())
    private var started = false

    fun schedule(context: Context) {
        if (started) {
            return
        }
        started = true
        val app = context.applicationContext
        val tick = object : Runnable {
            override fun run() {
                thread(name = "floanta-update") { check(app) }
                handler.postDelayed(this, intervalMs)
            }
        }
        handler.postDelayed(tick, firstDelayMs)
    }

    fun install(activity: Activity, url: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${activity.packageName}"),
            )
            activity.startActivity(intent)
            result.error(
                "install_permission",
                "Επίτρεψε την εγκατάσταση από αυτή την εφαρμογή και πάτα ξανά Ενημέρωση.",
                null,
            )
            return
        }
        thread(name = "floanta-apk") {
            try {
                val file = download(activity, url)
                activity.runOnUiThread {
                    openInstaller(activity, file)
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e(logTag, "Η λήψη απέτυχε", e)
                activity.runOnUiThread {
                    result.error("install", e.message ?: "Η λήψη απέτυχε", null)
                }
            }
        }
    }

    private fun check(context: Context) {
        try {
            val release = fetch() ?: return
            val current = currentVersion(context)
            if (current.isEmpty() || release.version.isEmpty() || release.downloadUrl.isEmpty()) {
                return
            }
            if (compareVersions(current, release.version) >= 0) {
                return
            }
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("floanta_update", true)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(logTag, "Ο έλεγχος έκδοσης απέτυχε", e)
        }
    }

    private fun fetch(): Release? {
        val connection = (URL(manifestUrl).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000
            readTimeout = 15000
            instanceFollowRedirects = true
        }
        try {
            if (connection.responseCode != 200) {
                return null
            }
            val body = connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            val json = JSONObject(body)
            return Release(
                version = json.optString("version").trim(),
                downloadUrl = json.optString("download_url").trim(),
            )
        } finally {
            connection.disconnect()
        }
    }

    private fun currentVersion(context: Context): String {
        return context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: ""
    }

    private fun download(context: Context, url: String): File {
        val dir = File(context.cacheDir, "updates")
        if (!dir.isDirectory && !dir.mkdirs()) {
            throw IllegalStateException("Δεν γράφτηκε ο φάκελος λήψης")
        }
        val name = url.substringAfterLast('/').substringBefore('?').ifBlank { "Floanta-Desk.apk" }
        val file = File(dir, name)
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 20000
            readTimeout = 120000
            instanceFollowRedirects = true
        }
        try {
            if (connection.responseCode != 200) {
                throw IllegalStateException("Η λήψη γύρισε ${connection.responseCode}")
            }
            connection.inputStream.use { input ->
                FileOutputStream(file).use { output -> input.copyTo(output) }
            }
        } finally {
            connection.disconnect()
        }
        if (!file.isFile || file.length() < 1024) {
            file.delete()
            throw IllegalStateException("Το αρχείο ενημέρωσης δεν είναι έγκυρο")
        }
        return file
    }

    private fun openInstaller(context: Context, file: File) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun compareVersions(a: String, b: String): Int {
        fun parts(value: String): List<Int> {
            val clean = value.split('+').first().split('-').first().trim()
            if (clean.isEmpty()) {
                return listOf(0)
            }
            return clean.split('.').map { it.toIntOrNull() ?: 0 }
        }
        val left = parts(a)
        val right = parts(b)
        val count = maxOf(left.size, right.size)
        for (index in 0 until count) {
            val x = left.getOrElse(index) { 0 }
            val y = right.getOrElse(index) { 0 }
            if (x != y) {
                return x.compareTo(y)
            }
        }
        return 0
    }

    private data class Release(val version: String, val downloadUrl: String)
}

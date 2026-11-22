package com.carriez.flutter_hbb

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Αντιγράφει το server και το key του APK στον φάκελο της εφαρμογής,
 * πριν ξεκινήσει ο native server.
 */
object FloantaServer {
    private const val logTag = "FloantaServer"
    const val FILE_NAME = "floanta_server.json"

    fun install(context: Context, homePath: String) {
        try {
            val text = context.assets.open(FILE_NAME).bufferedReader(Charsets.UTF_8).use { it.readText() }
            val dir = File(homePath)
            if (!dir.isDirectory && !dir.mkdirs()) {
                Log.e(logTag, "Δεν γράφτηκε ο φάκελος $homePath")
                return
            }
            File(dir, FILE_NAME).writeText(text)
        } catch (e: Exception) {
            Log.e(logTag, "Δεν αντιγράφηκε το $FILE_NAME", e)
        }
    }
}

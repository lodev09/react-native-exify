package com.exify

import android.content.Context
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.exify.ExifyUtils.formatTags
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import java.io.IOException

private const val ERROR_TAG = "E_EXIFY_ERROR"

class ExifyModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private val context: Context = reactContext

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun readAsync(uri: String, promise: Promise) {
    val photoUri = Uri.parse(uri)

    try {
      context.contentResolver.openInputStream(photoUri)?.use {
        val tags = formatTags(ExifInterface(it))
        it.close()

        promise.resolve(tags)
      }
    } catch (e: Exception) {
      promise.resolve(null)
      e.printStackTrace()
    }
  }

  @ReactMethod
  @Throws(IOException::class)
  fun writeAsync(uri: String, tags: ReadableMap, promise: Promise) {
    val photoUri = Uri.parse(uri)
    val params = Arguments.createMap()

    try {
      context.contentResolver.openFileDescriptor(photoUri, "rw", null)?.use { parcelDescriptor ->
        val exif = ExifInterface(parcelDescriptor.fileDescriptor)

        for ((_, tag) in EXIFY_TAGS) {
          if (!tags.hasKey(tag)) continue

          val type = tags.getType(tag)

          when (type) {
            ReadableType.Boolean -> exif.setAttribute(tag, tags.getBoolean(tag).toString())
            ReadableType.Number -> exif.setAttribute(tag, tags.getDouble(tag).toBigDecimal().toPlainString())
            ReadableType.String -> exif.setAttribute(tag, tags.getString(tag))
            ReadableType.Array -> exif.setAttribute(tag, tags.getArray(tag).toString())
            else -> exif.setAttribute(tag, tags.getString(tag))
          }
        }

        if (
          tags.hasKey(ExifInterface.TAG_GPS_LATITUDE) &&
          tags.hasKey(ExifInterface.TAG_GPS_LONGITUDE)
        ) {
          exif.setLatLong(
            tags.getDouble(ExifInterface.TAG_GPS_LATITUDE),
            tags.getDouble(ExifInterface.TAG_GPS_LONGITUDE)
          )
        }

        if (tags.hasKey(ExifInterface.TAG_GPS_ALTITUDE)) {
          exif.setAltitude(tags.getDouble(ExifInterface.TAG_GPS_ALTITUDE))
        }

        params.putString("uri", uri)
        params.putMap("tags", formatTags(exif))

        exif.saveAttributes()
        promise.resolve(params)
      }

    } catch (e: Exception) {
      promise.reject(ERROR_TAG, e.message, e)
      e.printStackTrace()
    }
  }

  companion object {
    const val NAME = "Exify"
  }
}

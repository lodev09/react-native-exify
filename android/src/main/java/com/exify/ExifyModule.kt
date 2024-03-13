package com.exify

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import java.io.IOException

class ExifyModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private val context: Context = reactContext

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun readAsync(uri: String, promise: Promise) {
    val photoUri = Uri.parse(uri)
    val params = Arguments.createMap()
    val tags = Arguments.createMap()

    try {
      context.contentResolver.openInputStream(photoUri)?.use { stream ->
        val exifInterface = ExifInterface(stream)

        for ((type, name) in EXIF_TAGS) {
          val attribute = exifInterface.getAttribute(name)
          if (attribute != null && attribute != "") {
            when (type) {
              "string" -> tags.putString(name, attribute)
              "int" -> tags.putInt(name, exifInterface.getAttributeInt(name, 0))
              "double" -> tags.putDouble(name, exifInterface.getAttributeDouble(name, 0.0))
              "array" -> {
                val array = Arguments.createArray()
                exifInterface.getAttributeRange(name)?.forEach { value ->
                  array.pushDouble(value.toDouble())
                }

                if (array.size() > 0) tags.putArray(name, array)
              }
            }
          }
        }

        // GPS
        exifInterface.latLong?.let { (lat, lng) ->
          tags.putDouble(ExifInterface.TAG_GPS_ALTITUDE, exifInterface.getAltitude(0.0))
          tags.putDouble(ExifInterface.TAG_GPS_LATITUDE, lat)
          tags.putDouble(ExifInterface.TAG_GPS_LONGITUDE, lng)
        }

        params.putString("uri", uri)
        params.putString("assetId", null)
        params.putMap("tags", tags)

        promise.resolve(params)
      }
    } catch (e: IOException) {
      Log.w(NAME, "Could not get exif from URI", e)
    }
  }

  @ReactMethod
  fun writeAsync(uri: String, data: ReadableMap, promise: Promise) {
    promise.resolve("Hello from writeAsync!")
  }

  companion object {
    const val NAME = "Exify"
  }
}

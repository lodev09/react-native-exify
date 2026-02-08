package com.lodev09.exify

import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.lodev09.exify.ExifyUtils.formatTags
import java.io.IOException

private const val ERROR_TAG = "E_EXIFY_ERROR"

class ExifyModule(
  reactContext: ReactApplicationContext,
) : NativeExifySpec(reactContext) {
  private val context = reactContext

  override fun read(
    uri: String,
    promise: Promise,
  ) {
    val photoUri = Uri.parse(uri)

    try {
      val inputStream =
        if (photoUri.scheme == "http" || photoUri.scheme == "https") {
          java.net.URL(uri).openStream()
        } else {
          context.contentResolver.openInputStream(photoUri)
        }

      inputStream?.use {
        val tags = formatTags(ExifInterface(it))
        promise.resolve(tags)
      }
    } catch (e: Exception) {
      promise.resolve(null)
      e.printStackTrace()
    }
  }

  @Throws(IOException::class)
  override fun write(
    uri: String,
    tags: ReadableMap,
    promise: Promise,
  ) {
    val photoUri = Uri.parse(uri)
    val params = Arguments.createMap()

    try {
      context.contentResolver.openFileDescriptor(photoUri, "rw", null)?.use { parcelDescriptor ->
        val exif = ExifInterface(parcelDescriptor.fileDescriptor)

        for ((valType, tag) in EXIFY_TAGS) {
          if (!tags.hasKey(tag)) continue

          val type = tags.getType(tag)

          when (type) {
            ReadableType.Boolean -> {
              exif.setAttribute(tag, tags.getBoolean(tag).toString())
            }

            ReadableType.Number -> {
              when (valType) {
                "double" -> exif.setAttribute(tag, tags.getDouble(tag).toBigDecimal().toPlainString())
                else -> exif.setAttribute(tag, tags.getDouble(tag).toInt().toString())
              }
            }

            ReadableType.String -> {
              exif.setAttribute(tag, tags.getString(tag))
            }

            ReadableType.Array -> {
              exif.setAttribute(tag, tags.getArray(tag).toString())
            }

            else -> {
              exif.setAttribute(tag, tags.getString(tag))
            }
          }
        }

        if (
          tags.hasKey(ExifInterface.TAG_GPS_LATITUDE) &&
          tags.hasKey(ExifInterface.TAG_GPS_LONGITUDE)
        ) {
          exif.setLatLong(
            tags.getDouble(ExifInterface.TAG_GPS_LATITUDE),
            tags.getDouble(ExifInterface.TAG_GPS_LONGITUDE),
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
    const val NAME = NativeExifySpec.NAME
  }
}

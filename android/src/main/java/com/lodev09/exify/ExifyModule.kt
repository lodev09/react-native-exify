package com.lodev09.exify

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener
import com.facebook.react.util.RNLog
import com.lodev09.exify.ExifyUtils.formatTags
import java.io.File
import java.io.IOException

private const val ERROR_TAG = "E_EXIFY_ERROR"
private const val MEDIA_LOCATION_REQUEST_CODE = 4209

class ExifyModule(
  reactContext: ReactApplicationContext,
) : NativeExifyModuleSpec(reactContext) {
  private val context = reactContext

  override fun read(
    uri: String,
    promise: Promise,
  ) {
    val photoUri = Uri.parse(uri)
    val scheme = photoUri.scheme

    if (scheme == null) {
      RNLog.w(context, "Exify: URI must include a scheme (e.g. file://): $uri")
      promise.reject(ERROR_TAG, "URI must include a scheme (e.g. file://): $uri")
      return
    }

    // On Android Q+, request ACCESS_MEDIA_LOCATION for unredacted GPS data
    if (scheme == "content" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
      ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_MEDIA_LOCATION) !=
      PackageManager.PERMISSION_GRANTED
    ) {
      val activity = context.currentActivity as? PermissionAwareActivity
      if (activity != null) {
        activity.requestPermissions(
          arrayOf(Manifest.permission.ACCESS_MEDIA_LOCATION),
          MEDIA_LOCATION_REQUEST_CODE,
          PermissionListener { requestCode, _, _ ->
            if (requestCode == MEDIA_LOCATION_REQUEST_CODE) {
              readExif(uri, photoUri, scheme, promise)
              true
            } else {
              false
            }
          },
        )
        return
      }
    }

    readExif(uri, photoUri, scheme, promise)
  }

  private fun readExif(
    uri: String,
    photoUri: Uri,
    scheme: String,
    promise: Promise,
  ) {
    try {
      val exif =
        if (scheme == "file") {
          ExifInterface(photoUri.path!!)
        } else {
          val inputStream =
            if (scheme == "content" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
              try {
                context.contentResolver.openInputStream(MediaStore.setRequireOriginal(photoUri))
              } catch (_: SecurityException) {
                context.contentResolver.openInputStream(photoUri)
              }
            } else if (scheme == "http" || scheme == "https") {
              java.net.URL(uri).openStream()
            } else {
              context.contentResolver.openInputStream(photoUri)
            }

          if (inputStream == null) {
            RNLog.w(context, "Exify: Could not open URI: $uri")
            promise.reject(ERROR_TAG, "Could not open URI: $uri")
            return
          }

          inputStream.use { ExifInterface(it) }
        }

      val tags = formatTags(exif)

      // ExifInterface ignores IFD0 tags placed in ExifIFD (non-standard but common
      // with some image editors). Fall back to raw EXIF parsing for missing tags.
      val missingTags =
        IFD0_STRING_TAGS.filter { !tags.hasKey(it) }.toSet()
      if (missingTags.isNotEmpty()) {
        val fallback =
          try {
            openInputStream(uri, photoUri, scheme)?.use { readFallbackTags(it, missingTags) }
          } catch (_: Exception) {
            null
          }
        fallback?.forEach { (tag, value) -> tags.putString(tag, value) }
      }

      promise.resolve(tags)
    } catch (e: Exception) {
      RNLog.w(context, "Exify: ${e.message}")
      promise.reject(ERROR_TAG, e.message, e)
    }
  }

  private fun openInputStream(
    uri: String,
    photoUri: Uri,
    scheme: String,
  ): java.io.InputStream? =
    when (scheme) {
      "file" -> File(photoUri.path!!).inputStream()
      "content" -> context.contentResolver.openInputStream(photoUri)
      else -> java.net.URL(uri).openStream()
    }

  @Throws(IOException::class)
  override fun write(
    uri: String,
    tags: ReadableMap,
    promise: Promise,
  ) {
    val photoUri = Uri.parse(uri)

    if (photoUri.scheme == null) {
      RNLog.w(context, "Exify: URI must include a scheme (e.g. file://): $uri")
      promise.reject(ERROR_TAG, "URI must include a scheme (e.g. file://): $uri")
      return
    }

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
                "double" -> {
                  val value = tags.getDouble(tag)
                  if (tag.startsWith("GPS")) {
                    exif.setAttribute(tag, ExifyUtils.decimalToRational(value))
                  } else {
                    exif.setAttribute(tag, value.toBigDecimal().toPlainString())
                  }
                }
                else -> exif.setAttribute(tag, tags.getDouble(tag).toInt().toString())
              }
            }

            ReadableType.String -> {
              exif.setAttribute(tag, tags.getString(tag))
            }

            ReadableType.Array -> {
              val arr = tags.getArray(tag)!!
              val values = (0 until arr.size()).joinToString(", ") { arr.getInt(it).toString() }
              exif.setAttribute(tag, values)
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
          val hasExplicitRef =
            tags.hasKey(ExifInterface.TAG_GPS_LATITUDE_REF) ||
              tags.hasKey(ExifInterface.TAG_GPS_LONGITUDE_REF)

          if (hasExplicitRef) {
            val lat = tags.getDouble(ExifInterface.TAG_GPS_LATITUDE)
            val lng = tags.getDouble(ExifInterface.TAG_GPS_LONGITUDE)
            val latRef =
              if (tags.hasKey(ExifInterface.TAG_GPS_LATITUDE_REF)) {
                tags.getString(ExifInterface.TAG_GPS_LATITUDE_REF)
              } else {
                if (lat >= 0) "N" else "S"
              }
            val lngRef =
              if (tags.hasKey(ExifInterface.TAG_GPS_LONGITUDE_REF)) {
                tags.getString(ExifInterface.TAG_GPS_LONGITUDE_REF)
              } else {
                if (lng >= 0) "E" else "W"
              }

            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, ExifyUtils.decimalToDms(Math.abs(lat)))
            exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, latRef)
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, ExifyUtils.decimalToDms(Math.abs(lng)))
            exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, lngRef)
          } else {
            exif.setLatLong(
              tags.getDouble(ExifInterface.TAG_GPS_LATITUDE),
              tags.getDouble(ExifInterface.TAG_GPS_LONGITUDE),
            )
          }
        }

        if (tags.hasKey(ExifInterface.TAG_GPS_ALTITUDE)) {
          val alt = tags.getDouble(ExifInterface.TAG_GPS_ALTITUDE)
          if (tags.hasKey(ExifInterface.TAG_GPS_ALTITUDE_REF)) {
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE, ExifyUtils.decimalToRational(Math.abs(alt)))
            exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE_REF, tags.getInt(ExifInterface.TAG_GPS_ALTITUDE_REF).toString())
          } else {
            exif.setAltitude(alt)
          }
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
    const val NAME = NativeExifyModuleSpec.NAME
  }
}

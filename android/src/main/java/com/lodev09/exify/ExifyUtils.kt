package com.lodev09.exify

import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import java.io.InputStream

object ExifyUtils {
  @JvmStatic
  fun formatTags(exif: ExifInterface): ReadableMap {
    val tags = Arguments.createMap()

    for ((type, tag) in EXIFY_TAGS) {
      val attribute = exif.getAttribute(tag)
      if (attribute != null && attribute != "") {
        when (type) {
          "string" -> tags.putString(tag, attribute)
          "int" -> tags.putInt(tag, exif.getAttributeInt(tag, 0))
          "double" -> tags.putDouble(tag, exif.getAttributeDouble(tag, 0.0))
          "array" -> {
            val array = Arguments.createArray()
            exif.getAttributeRange(tag)?.forEach { value ->
              array.pushDouble(value.toDouble())
            }

            if (array.size() > 0) tags.putArray(tag, array)
          }
        }
      }
    }

    // GPS
    exif.latLong?.let {
      tags.putDouble(ExifInterface.TAG_GPS_ALTITUDE, exif.getAltitude(0.0))
      tags.putDouble(ExifInterface.TAG_GPS_LATITUDE, it[0])
      tags.putDouble(ExifInterface.TAG_GPS_LONGITUDE, it[1])
    }

    return tags
  }
}

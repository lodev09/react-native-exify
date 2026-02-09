package com.lodev09.exify

import androidx.exifinterface.media.ExifInterface
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap

object ExifyUtils {
  @JvmStatic
  fun formatTags(exif: ExifInterface): ReadableMap {
    val tags = Arguments.createMap()

    for ((type, tag) in EXIFY_TAGS) {
      val attribute = exif.getAttribute(tag)
      if (attribute != null && attribute != "") {
        when (type) {
          "string" -> {
            tags.putString(tag, attribute)
          }

          "int" -> {
            tags.putInt(tag, exif.getAttributeInt(tag, 0))
          }

          "double" -> {
            tags.putDouble(tag, exif.getAttributeDouble(tag, 0.0))
          }

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

    // GPS — return absolute values (sign is in LatitudeRef/LongitudeRef)
    exif.latLong?.let {
      tags.putDouble(ExifInterface.TAG_GPS_ALTITUDE, Math.abs(exif.getAltitude(0.0)))
      tags.putDouble(ExifInterface.TAG_GPS_LATITUDE, Math.abs(it[0]))
      tags.putDouble(ExifInterface.TAG_GPS_LONGITUDE, Math.abs(it[1]))
    }

    return tags
  }

  @JvmStatic
  fun decimalToDms(decimal: Double): String {
    val degrees = decimal.toInt()
    val minutesDecimal = (decimal - degrees) * 60
    val minutes = minutesDecimal.toInt()
    val seconds = ((minutesDecimal - minutes) * 60 * 10000).toLong()
    return "$degrees/1,$minutes/1,$seconds/10000"
  }

  @JvmStatic
  fun decimalToRational(value: Double): String {
    val numerator = (value * 10000).toLong()
    return "$numerator/10000"
  }
}

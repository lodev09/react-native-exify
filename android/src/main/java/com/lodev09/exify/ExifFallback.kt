package com.lodev09.exify

import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * IFD0 string tags that ExifInterface may miss when an image editor
 * (e.g. ON1 Photo RAW) places them inside the ExifIFD instead of IFD0.
 *
 * Maps EXIF tag number → ExifInterface tag name.
 */
private val FALLBACK_TAGS =
  mapOf(
    0x010F to "Make",
    0x0110 to "Model",
    0x013B to "Artist",
    0x8298 to "Copyright",
    0x010E to "ImageDescription",
    0x0131 to "Software",
  )

private const val IFD_FORMAT_STRING = 2
private const val IFD_FORMAT_UNDEFINED = 7
private const val EXIF_IFD_POINTER_TAG = 0x8769

/**
 * Scans raw JPEG bytes for IFD0 string tags that may have been placed in
 * the ExifIFD. Returns a map of tag name → value for any tags found.
 */
fun readFallbackTags(
  inputStream: InputStream,
  missingTags: Set<String>,
): Map<String, String> {
  if (missingTags.isEmpty()) return emptyMap()

  val neededTagNumbers = FALLBACK_TAGS.filterValues { it in missingTags }.keys
  if (neededTagNumbers.isEmpty()) return emptyMap()

  val bytes = readExifSegment(inputStream) ?: return emptyMap()
  val result = mutableMapOf<String, String>()

  val app1 = findApp1Exif(bytes) ?: return emptyMap()
  val tiffOffset = app1.tiffOffset
  val buf = ByteBuffer.wrap(bytes)
  buf.order(app1.byteOrder)

  // Read IFD0 to find ExifIFD offset (offsets are relative to TIFF start)
  val ifd0Offset = buf.getInt(tiffOffset + 4)
  val exifIfdOffset = findExifIfdOffset(buf, tiffOffset, ifd0Offset) ?: return emptyMap()

  // Scan ExifIFD entries for our missing tags
  scanIfd(buf, tiffOffset, exifIfdOffset, neededTagNumbers, result)

  return result
}

/**
 * Reads only the JPEG header segments up to and including the EXIF APP1,
 * avoiding reading the full image file into memory.
 */
private fun readExifSegment(inputStream: InputStream): ByteArray? {
  val dis = java.io.DataInputStream(inputStream)
  val header = ByteArray(2)
  dis.readFully(header)
  if (header[0] != 0xFF.toByte() || header[1] != 0xD8.toByte()) return null

  val out = java.io.ByteArrayOutputStream(65536)
  out.write(header)

  val segHeader = ByteArray(4)
  while (true) {
    try {
      dis.readFully(segHeader)
    } catch (_: java.io.EOFException) {
      break
    }
    val marker = segHeader[1].toInt() and 0xFF
    val segLen = ((segHeader[2].toInt() and 0xFF) shl 8) or (segHeader[3].toInt() and 0xFF)

    if (segHeader[0] != 0xFF.toByte() || segLen < 2) break

    out.write(segHeader)
    val segData = ByteArray(segLen - 2)
    dis.readFully(segData)
    out.write(segData)

    // Found EXIF APP1 — we have enough
    if (marker == 0xE1 && segData.size >= 6 &&
      segData[0] == 0x45.toByte() &&
      segData[1] == 0x78.toByte() &&
      segData[2] == 0x69.toByte() &&
      segData[3] == 0x66.toByte()
    ) {
      break
    }

    // Stop if we hit SOS or image data
    if (marker == 0xDA) break
  }

  return out.toByteArray()
}

private data class App1Info(val tiffOffset: Int, val byteOrder: ByteOrder)

private fun findApp1Exif(bytes: ByteArray): App1Info? {
  if (bytes.size < 4 || bytes[0] != 0xFF.toByte() || bytes[1] != 0xD8.toByte()) return null

  var pos = 2
  while (pos + 4 < bytes.size) {
    if (bytes[pos] != 0xFF.toByte()) return null
    val marker = bytes[pos + 1].toInt() and 0xFF

    // Read segment length (big-endian)
    val segLen = ((bytes[pos + 2].toInt() and 0xFF) shl 8) or (bytes[pos + 3].toInt() and 0xFF)

    if (marker == 0xE1 && segLen >= 8) {
      // Check for "Exif\0\0"
      if (pos + 10 < bytes.size &&
        bytes[pos + 4] == 0x45.toByte() && // E
        bytes[pos + 5] == 0x78.toByte() && // x
        bytes[pos + 6] == 0x69.toByte() && // i
        bytes[pos + 7] == 0x66.toByte() && // f
        bytes[pos + 8] == 0x00.toByte() &&
        bytes[pos + 9] == 0x00.toByte()
      ) {
        val tiffOffset = pos + 10
        val order =
          if (bytes[tiffOffset] == 0x49.toByte() && bytes[tiffOffset + 1] == 0x49.toByte()) {
            ByteOrder.LITTLE_ENDIAN
          } else {
            ByteOrder.BIG_ENDIAN
          }
        return App1Info(tiffOffset, order)
      }
    }

    pos += 2 + segLen
  }
  return null
}

private fun findExifIfdOffset(
  buf: ByteBuffer,
  tiffOffset: Int,
  ifdOffset: Int,
): Int? {
  if (ifdOffset < 0 || tiffOffset + ifdOffset + 2 > buf.limit()) return null

  val count = buf.getShort(tiffOffset + ifdOffset).toInt() and 0xFFFF
  for (i in 0 until count) {
    val entryOffset = tiffOffset + ifdOffset + 2 + i * 12
    if (entryOffset + 12 > buf.limit()) return null

    val tagNumber = buf.getShort(entryOffset).toInt() and 0xFFFF
    if (tagNumber == EXIF_IFD_POINTER_TAG) {
      return buf.getInt(entryOffset + 8)
    }
  }
  return null
}

private fun scanIfd(
  buf: ByteBuffer,
  tiffOffset: Int,
  ifdOffset: Int,
  neededTagNumbers: Set<Int>,
  result: MutableMap<String, String>,
) {
  val absOffset = tiffOffset + ifdOffset
  if (absOffset + 2 > buf.limit()) return

  val count = buf.getShort(absOffset).toInt() and 0xFFFF
  for (i in 0 until count) {
    val entryOffset = absOffset + 2 + i * 12
    if (entryOffset + 12 > buf.limit()) return

    val tagNumber = buf.getShort(entryOffset).toInt() and 0xFFFF
    if (tagNumber !in neededTagNumbers) continue

    val format = buf.getShort(entryOffset + 2).toInt() and 0xFFFF
    val componentCount = buf.getInt(entryOffset + 4)

    if (format != IFD_FORMAT_STRING && format != IFD_FORMAT_UNDEFINED) continue
    if (componentCount <= 0 || componentCount > 1024) continue

    val dataOffset =
      if (componentCount <= 4) {
        entryOffset + 8
      } else {
        tiffOffset + buf.getInt(entryOffset + 8)
      }

    if (dataOffset < 0 || dataOffset + componentCount > buf.limit()) continue

    val strBytes = ByteArray(componentCount)
    buf.position(dataOffset)
    buf.get(strBytes)

    // Trim trailing null bytes
    var len = strBytes.size
    while (len > 0 && strBytes[len - 1] == 0.toByte()) len--
    if (len == 0) continue

    val tagName = FALLBACK_TAGS[tagNumber] ?: continue
    result[tagName] = String(strBytes, 0, len, Charsets.UTF_8).trim()
  }
}

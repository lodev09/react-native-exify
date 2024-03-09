import type { Position } from './types'

/**
 * Mock position in [lng, lat]
 */
export const mockPosition = (
  center: Position = [-105.358887, 39.113014],
  radiusKm = 10,
): Position => {
  const centerLng = center[0]
  const centerLat = center[1]

  const randomRadius = Math.sqrt(Math.random()) * radiusKm // Ensure even distribution

  // Generate a random angle in radians
  const angle = Math.random() * 2 * Math.PI

  // Calculate the new coordinates
  const lat = centerLat + (randomRadius / 111.32) * Math.cos(angle)
  const lng =
    centerLng + (randomRadius / (111.32 * Math.cos(centerLat * (Math.PI / 180)))) * Math.sin(angle)

  return [lng, lat]
}

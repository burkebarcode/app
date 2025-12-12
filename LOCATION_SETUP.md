# Location Services Setup

To enable the map-based venue search feature, you need to add location permissions to your Xcode project.

## Steps:

1. Open the Xcode project
2. Select the **barcode** target
3. Go to the **Info** tab
4. Add the following keys to **Custom iOS Target Properties**:

### Required Keys:

- **Key**: `NSLocationWhenInUseUsageDescription`
  - **Type**: String
  - **Value**: "We need your location to find nearby bars and restaurants for you to rate."

- **Key**: `NSLocationAlwaysAndWhenInUseUsageDescription`
  - **Type**: String
  - **Value**: "We need your location to find nearby bars and restaurants for you to rate."

## Alternative: Add to Info.plist

If your project has an Info.plist file, add these entries:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby bars and restaurants for you to rate.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to find nearby bars and restaurants for you to rate.</string>
```

## Features Enabled:

Once location permissions are added, users will be able to:
- View a map with nearby bars and restaurants
- See venues sorted by distance from their current location
- Search for venues in their current area
- Tap on map pins to see venue details
- Create venues directly from Apple Maps search results

The map search can be accessed by tapping the **map icon** in the top right of the venue search screen.

# VirtualTourist

This app allows users to specify travel locations around the world, and create virtual photo albums and places for each location. The locations, photo albums and places is stored in Core Data. The app uses the Flickr and Google Places API.

The app has three view controller scenes.

<b>Travel Locations:</b>
Allows the user to drop pins around the world. Users can drag pin to a new location after dropping them. As soon as a pin is dropped the Photo data for the pin location is fetched from Flickr. The actual photo downloads occur in the Photos view controller.

<b>Photo Album View:</b>
Allows the users to download and edit an album for a location. Users can create new collections and delete photos from existing albums.

<b>Places View:</b>
Fetches interesting Places related to a pin. Allows users to delete places for a given location.

<b>Video demo:</b>
https://youtu.be/vMn74FKFrvc

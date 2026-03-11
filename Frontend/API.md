# PicFolio API Documentation

## Base URL Conguration

**IMPORTANT:** All API endpoints listed below are relative paths. You must congure a base URL variable
in your application that points to your server. The base URL may change based on your deployment
environment.
BASE_URL = "http://your-server-address:7251"

Example: [http://localhost:7251](http://localhost:7251) or [http://192.168.1.100:](http://192.168.1.100:)

All API calls should be prexed with this base URL. For example:
Full URL: {BASE_URL}/api/users
Becomes: [http://localhost:7251/api/users](http://localhost:7251/api/users)

## API Endpoints

## 1. Root Endpoint

#### GET /

**Description:** Simple health check endpoint that returns a greeting message to verify the server is
running.
**Method:** GET

**Parameters:** None
**Request Body:** None
**Response:**
"Hello There!"

**Example:**

```
curl http://localhost:7251/
```

## USER MANAGEMENT APIs

### 2. Create User

```
POST /api/user/create
```

**Description:** Creates a new user account in the system. This endpoint registers a new username and
password combination. The user data is stored in the conguration and a new database is created for
the user.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The desired username for the new user
password (string, required): The password for the new user

**Response:**
Success: "true" (string)
Error: "User already exists" or "Improper data sent"

**Example:**

```
curl -X POST http://localhost:7251/api/user/create \
-F "username=john_doe" \
-F "password=secure123"
```

### 3. Rename User

```
POST /api/user/rename/<username>/<new_username>
```

**Description:** Renames an existing user account. This endpoint updates the username in the system
conguration and renames the user's data directory. The old username must exist and the new
username must not already be in use.
**Method:** POST

**Path Parameters:**

```
username (string, required): The current username to be renamed
new_username (string, required): The new username to assign
```

**Request Body:** None
**Response:**
Success: {"message": "User renamed successfully"}
Error: {"error": "User not found"} (404) or {"error": "User already
exists"} (400)

**Example:**

```
curl -X POST http://localhost:7251/api/user/rename/john_doe/johnny
```

### 4. Authenticate User

```
POST /api/user/auth
```

**Description:** Authenticates a user by verifying their username and password credentials. This endpoint
checks if the provided credentials match the stored user data and grants access if valid.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username to authenticate
password (string, required): The password to verify

**Response:**
Success: "true" (string)
Error: "User not found" or "Incorrect password"

**Example:**

```
curl -X POST http://localhost:7251/api/user/auth \
-F "username=john_doe" \
-F "password=secure123"
```

### 5. Get All Users

```
GET /api/users
```

**Description:** Retrieves a list of all registered usernames in the system. This endpoint returns an array of
usernames that can be used for user selection or administrative purposes.
**Method:** GET

**Parameters:** None
**Request Body:** None
**Response:**

```
["user1", "user2", "user3"]
```

**Example:**

```
curl http://localhost:7251/api/users
```

### 6. Delete User

```
DELETE /api/user/delete/<username>
```

**Description:** Permanently deletes a user account from the system. This endpoint removes the user
from the conguration and deletes all associated data including the user's entire directory structure
with all photos, videos, and metadata.
**Method:** DELETE

**Path Parameters:**
username (string, required): The username to delete

**Request Body:** None
**Response:**
Success: {"message": "User deleted successfully"}
Error: {"error": "User not found"} (404)

**Example:**

```
curl -X DELETE http://localhost:7251/api/user/delete/john_doe
```

## ASSET MANAGEMENT APIs

### 7. Upload Asset

```
POST /api/upload
```

**Description:** Uploads a photo or video le to the user's library. The endpoint processes the le, extracts
EXIF metadata (date, time, GPS coordinates), stores the original le, and queues it for preview
generation and processing in the background.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the asset
asset (le, required): The photo or video le to upload
compress (string, optional): If present, marks the asset for compression

**Supported File Formats:**
Images: png, jpg, jpeg, avif, heic, ttif, webp, jf
Videos: mp4, mov, avi, webm, v, wmv, mkv
**Response:**
Success: {"message": "Uploaded successfully"}
Error: {"error": "User not found"} (404) or {"error": "Invalid file type"}
(400)
**Example:**

```
curl -X POST http://localhost:7251/api/upload \
-F "username=john_doe" \
-F "asset=@/path/to/photo.jpg" \
-F "compress=true"
```

### 8. Delete Assets

```
DELETE /api/delete/<username>/<ids>
```

**Description:** Marks assets for deletion or permanently deletes them. When rst called, assets are
moved to trash with a 90-day retention period. When called on already-deleted assets, they are
permanently removed from storage. Multiple assets can be deleted at once by providing comma-
separated IDs.
**Method:** DELETE

**Path Parameters:**
username (string, required): The username who owns the assets
ids (string, required): Comma-separated list of asset IDs to delete (e.g., "1,2,3")

**Request Body:** None
**Response:**

```
{
"success": ["1", "2"],
"failed": ["3"]
}
```

**Example:**

```
curl -X DELETE http://localhost:7251/api/delete/john_doe/1,2,
```

### 9. Restore Deleted Assets

```
POST /api/restore
```

**Description:** Restores previously deleted assets from the trash back to the main library. This operation
can be performed on assets within the 90-day retention period before permanent deletion.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the assets

```
ids (string, required): Comma-separated list of asset IDs to restore (e.g., "1,2,3")
```

**Response:**

```
{
"success": ["1", "2"],
"failed": ["3"]
}
```

**Example:**

```
curl -X POST http://localhost:7251/api/restore \
-F "username=john_doe" \
-F "ids=1,2,3"
```

### 10. Get Asset Preview (with Date)

```
GET /api/preview/<username>/<photo_id>/<yyyy>/<mm>/<dd>
```

**Description:** Retrieves the preview/thumbnail version of an asset when you know the exact date.
Preview les are optimized for fast loading and bandwidth eciency - images are in WebP format and
videos are converted to GIF or MP4.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
photo_id (integer, required): The asset ID
yyyy (integer, required): Year of asset creation
mm (integer, required): Month of asset creation
dd (integer, required): Day of asset creation

**Request Body:** None
**Response:** Binary le data (image/webp, image/gif, or video/mp4)
**Example:**

```
curl http://localhost:7251/api/preview/john_doe/123/2024/03/15 --output p
```

### 11. Get Asset Preview (without Date)

```
GET /api/preview/<username>/<photo_id>
```

**Description:** Retrieves the preview/thumbnail version of an asset without requiring date information.
The endpoint automatically looks up the creation date from the database and returns the appropriate
preview le.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
photo_id (integer, required): The asset ID

**Request Body:** None
**Response:** Binary le data (image/webp or image/gif)
**Example:**

### 12. Get Original Asset (with Date)

```
GET /api/asset/<username>/<photo_id>/<yyyy>/<mm>/<dd>
```

**Description:** Retrieves the original full-resolution version of an asset when you know the exact creation
date. This returns the master copy stored in PNG format for images or MP4 for videos at original quality.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
photo_id (integer, required): The asset ID
yyyy (integer, required): Year of asset creation
mm (integer, required): Month of asset creation
dd (integer, required): Day of asset creation

**Request Body:** None
**Response:** Binary le data (image/png or video/mp4)

```
curl http://localhost:7251/api/preview/john_doe/123 --output preview.webp
```

**Example:**

### 13. Get Original Asset (without Date)

```
GET /api/asset/<username>/<photo_id>
```

**Description:** Retrieves the original full-resolution version of an asset without requiring date
information. The endpoint queries the database for the creation date and returns the master le from
the appropriate storage location.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
photo_id (integer, required): The asset ID

**Request Body:** None
**Response:** Binary le data (image/png or video/mp4)
**Example:**

### 14. Get General Asset List

```
POST /api/list/general
```

**Description:** Retrieves a paginated list of assets grouped by creation date. Each page contains up to 4
date groups with all assets from those dates. This is the main endpoint for displaying the photo library in
chronological order.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose assets to retrieve

```
curl http://localhost:7251/api/asset/john_doe/123/2024/03/15 --output ori
```

```
curl http://localhost:7251/api/asset/john_doe/123 --output original.png
```

```
page (integer, required): Page number starting from 0
```

**Response:**

```
[
[
"2024-03-15",
[
[123],
[124, null, "3:25"],
[125]
]
],
[
"2024-03-14",
[
[126],
[127]
]
]
]
```

Note: Arrays with 3 elements indicate videos - [id, null, duration]. Arrays with 1 element are
images - [id].

**Example:**

```
curl -X POST http://localhost:7251/api/list/general \
-F "username=john_doe" \
-F "page=0"
```

### 15. Get Simple Asset List

```
GET /api/list/<username>
```

**Description:** Returns a simple array of all asset IDs for a user, with one representative ID per date. This
is useful for getting a quick overview or count of unique dates in the library.
**Method:** GET

**Path Parameters:**

```
username (string, required): The username whose assets to retrieve
```

**Request Body:** None
**Response:**

```
[123, 126, 130, 145]
```

**Example:**

```
curl http://localhost:7251/api/list/john_doe
```

### 16. Get Asset Details

```
GET /api/details/<username>/<photo_id>
```

**Description:** Retrieves comprehensive metadata for a specic asset including lename, tags, creation
date/time, format, dimensions, le size, compression status, faces detected, and location information.
This is used for the asset detail view.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
photo_id (integer, required): The asset ID

**Request Body:** None
**Response:**

```
{
"name": "IMG_1234.jpg",
"tags": ["sunset", "beach", "ocean"],
"date": "15-03-2024",
"time": "06:30 PM",
"format": "jpg",
"compress": true,
"mp": "12 MP",
"width": "4000",
"height": "3000",
"size": "3.45 MB",
```

```
"faces": [[1, "John"], [2, "Unknown"]],
"location": null
}
```

**Example:**

```
curl http://localhost:7251/api/details/john_doe/
```

### 17. Redate Assets

```
POST /api/redate
```

**Description:** Changes the creation date of one or more assets. This updates both the database
metadata and physically moves the les to new date-based directory structures. Useful for correcting
dates on imported photos or organizing assets.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the assets
date (string, required): New date in YYYY-MM-DD format
id (string, required): Comma-separated list of asset IDs to redate

**Response:**
Success: "Date changed successfully"
Error: "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/redate \
-F "username=john_doe" \
-F "date=2024-01-15" \
-F "id=123,124,125"
```

### 18. Get Deleted Assets List

```
POST /api/list/deleted
```

**Description:** Retrieves all assets currently in the trash, grouped by deletion date. Shows how many days
remain until permanent deletion (90-day retention period). This powers the trash/bin view in the
application.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose deleted assets to retrieve

**Response:**

```
[
[
"5",
[
[123],
[124, null, "2:15"]
]
],
[
"12",
[
[125]
]
]
]
```

Note: First element is days until permanent deletion.
**Example:**

```
curl -X POST http://localhost:7251/api/list/deleted \
-F "username=john_doe"
```

### 19. Like/Unlike Asset

```
POST /api/like/<username>/<asset_id>
```

**Description:** Toggles the like status of an asset. If the asset is not liked, it marks it as liked. If already
liked, it removes the like. This is used for creating favorites collections.

**Method:** POST

**Path Parameters:**
username (string, required): The username who owns the asset
asset_id (integer, required): The asset ID to like/unlike

**Request Body:** None
**Response:**
Success: "Success"
Error: "User not found" (404)

**Example:**

```
curl -X POST http://localhost:7251/api/like/john_doe/
```

### 20. Check If Asset Is Liked

```
GET /api/liked/<username>/<asset_id>
```

**Description:** Checks whether a specic asset is currently marked as liked/favorited by the user.
Returns a boolean value indicating the like status.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the asset
asset_id (integer, required): The asset ID to check

**Request Body:** None
**Response:**

```
true
```

or

```
false
```

**Example:**

```
curl http://localhost:7251/api/liked/john_doe/
```

### 21. Get Duplicate Assets

```
POST /api/list/duplicate
```

**Description:** Retrieves a list of duplicate assets detected in the library. The system identies visually
similar or identical photos/videos and groups them together for user review and potential cleanup.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose duplicates to retrieve

**Response:**

```
[
["2024-03-15", 123, 124],
["2024-03-10", 130, 131]
]
```

Note: Each array contains [creation_date, asset_id1, asset_id2]
**Example:**

```
curl -X POST http://localhost:7251/api/list/duplicate \
-F "username=john_doe"
```

## FACE RECOGNITION APIs

### 22. Get Faces List

```
POST /api/list/faces
```

**Description:** Retrieves all detected faces in the user's library, ordered by frequency of appearance.
Each face has a unique ID and either a user-assigned name or "Unknown" if not yet identied. This
powers the people/faces gallery view.

**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose faces to retrieve

**Response:**

```
[
[1, "John Doe"],
[2, "Jane Smith"],
[3, "Unknown"],
[4, "Unknown"]
]
```

Note: Each array contains [face_id, name]
**Example:**

```
curl -X POST http://localhost:7251/api/list/faces \
-F "username=john_doe"
```

### 23. Get Assets for Specic Face

```
GET /api/list/face/<username>/<face_id>
```

**Description:** Retrieves all assets containing a specic person/face, grouped by creation date. This
allows viewing all photos and videos where a particular person appears.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the assets
face_id (integer, required): The face ID to lter by

**Request Body:** None
**Response:**

#### [

#### [

#### "2024-03-15",

#### [

#### [123],

```
[124, null, "3:25"],
[125]
]
],
[
"2024-03-14",
[
[126]
]
]
]
```

**Example:**

```
curl http://localhost:7251/api/list/face/john_doe/
```

### 24. Get Face Name and Count

```
GET /api/face/name/<username>/<face_id>
```

**Description:** Retrieves the name assigned to a specic face along with the count of how many assets
contain that face. Returns "Unknown" for faces that haven't been identied yet.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the face data
face_id (integer, required): The face ID to query

**Request Body:** None
**Response:**

```
["John Doe", 45]
```

Note: Array contains [name, count_of_assets]
**Example:**

```
curl http://localhost:7251/api/face/name/john_doe/
```

### 25. Get Face Image

```
GET /api/face/image/<username>/<face_id>
```

**Description:** Retrieves the thumbnail/representative image for a specic face. This is typically a
cropped version of the face used for display in the faces gallery.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the face data
face_id (integer, required): The face ID

**Request Body:** None
**Response:** Binary image data (image/webp)
**Example:**

### 26. Get Faces in Asset

```
GET /api/assetface/<asset>
```

**Description:** Retrieves all faces detected in a specic asset along with their bounding box coordinates.
This is used for displaying face detection overlays and allowing face identication/tagging in the UI.
**Method:** GET

**Path Parameters:**
asset (integer, required): The asset ID to query

**Request Body (Form Data - Optional):**

```
curl http://localhost:7251/api/face/image/john_doe/1 --output face.webp
```

```
username (string, optional): The username who owns the asset
```

**Response:**

```
[
{
"faceid": 1,
"x": 100,
"y": 150,
"w": 200,
"h": 200
},
{
"faceid": 2,
"x": 400,
"y": 180,
"w": 180,
"h": 180
}
]
```

**Example:**

```
curl http://localhost:7251/api/assetface/
```

### 27. Join/Merge Faces

```
POST /api/face/join
```

**Description:** Merges two face identities into one. This is used when the system detects the same
person as two different faces. All assets tagged with the secondary face will be updated to use the main
face, and the secondary face data is removed.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the face data
main_face_id1 (integer, required): The face ID to keep
side_face_id2 (integer, required): The face ID to merge and remove

**Response:**
Success: "Faces joined successfully"
Error: "Faces are same" (400), "User not found" (404), or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/face/join \
-F "username=john_doe" \
-F "main_face_id1=1" \
-F "side_face_id2=3"
```

### 28. Add Face to Asset

```
POST /api/face/add
```

**Description:** Manually associates a face identity with an asset. This is used when the automatic face
detection missed a face or when manually tagging people in photos.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the asset
asset_id (integer, required): The asset ID to tag
face_id (integer, required): The face ID to add

**Response:**
Success: "Face added successfully"
Error: "User not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/face/add \
-F "username=john_doe" \
-F "asset_id=123" \
-F "face_id=1"
```

### 29. Remove Face from Asset

```
POST /api/face/remove
```

**Description:** Removes a face association from one or more assets. This unlinks a person's identication
from specic photos/videos, useful for correcting misidentications.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the assets
asset_id (string, required): Comma-separated list of asset IDs
face_id (integer, required): The face ID to remove

**Response:**
Success: "Face removed successfully"
Error: "User not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/face/remove \
-F "username=john_doe" \
-F "asset_id=123,124,125" \
-F "face_id=1"
```

### 30. Replace Face in Asset

```
POST /api/face/replace/<new_face_id>/<asset_id>/<x>/<y>/<w>/<h>/
```

**Description:** Replaces a face identication at a specic location in an asset with a different face ID.
This uses coordinates to precisely identify which face in a photo should be reassigned when multiple
faces are present.
**Method:** POST

**Path Parameters:**
new_face_id (integer, required): The new face ID to assign
asset_id (integer, required): The asset ID containing the face
x (integer, required): X coordinate of face bounding box
y (integer, required): Y coordinate of face bounding box

```
w (integer, required): Width of face bounding box
h (integer, required): Height of face bounding box
```

**Request Body (Form Data - Optional):**
username (string, optional): The username who owns the asset

**Response:**
Success: "Faces replaced successfully"
Error: "Face not found" (404)

**Example:**

### 31. Rename Face

```
GET /api/face/rename/<username>/<face_id>/<name>
```

**Description:** Assigns or updates the name for a specic face identity. This allows identifying "Unknown"
faces or correcting names. All assets with this face will now show the updated name.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the face data
face_id (integer, required): The face ID to rename
name (string, required): The new name to assign

**Request Body:** None
**Response:**
Success: "Face renamed successfully"
Error: "User not found" (404) or "Face not found" (404)

**Example:**

```
curl http://localhost:7251/api/face/rename/john_doe/3/Jane%20Smith
```

```
curl -X POST http://localhost:7251/api/face/replace/2/123/100/150/200/200
```

### 32. Remove Name from Faces

```
POST /api/face/noname
```

**Description:** Reverts named faces back to "Unknown" status by replacing their names with random
UUIDs. This is useful for unmarking faces or resetting face identications for re-training.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the face data
name (string, required): Comma-separated list of face IDs to unname

**Response:**
Success: "Faces renamed successfully"
Error: "User not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/face/noname \
-F "username=john_doe" \
-F "name=1,2,3"
```

## ALBUM MANAGEMENT APIs

### 33. Get Albums List

```
POST /api/list/albums
```

**Description:** Retrieves all user-created albums with their metadata including album ID, name, cover
image, and start date. Albums are manual collections organized by the user.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose albums to retrieve

**Response:**

```
[
["1", "Summer Vacation 2024", "123", "2024-06-01"],
["2", "Birthday Party", "156", "2024-03-15"],
["3", "Wedding", "200", "2024-02-14"]
]
```

Note: Each array contains [album_id, name, cover_image_id, start_date]
**Example:**

```
curl -X POST http://localhost:7251/api/list/albums \
-F "username=john_doe"
```

### 34. Create Album

```
POST /api/album/create
```

**Description:** Creates a new empty album with a specied name. After creation, assets can be added to
the album using the add endpoint. The rst asset added will automatically become the cover image.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who will own the album
name (string, required): The name for the new album

**Response:**
Success: "Album created successfully"
Error: "username not found" (404)

**Example:**

```
curl -X POST http://localhost:7251/api/album/create \
-F "username=john_doe" \
-F "name=Summer Trip 2024"
```

### 35. Add Assets to Album

```
POST /api/album/add
```

**Description:** Adds one or more assets to an existing album. If the album doesn't have a cover image, the
rst asset added will be set as the cover. Multiple assets can be added at once.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the album
album_id (integer, required): The album ID to add assets to
asset_id (string, required): Comma-separated list of asset IDs to add

**Response:**
Success: "Photos added to album successfully"
Error: "username not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/album/add \
-F "username=john_doe" \
-F "album_id=1" \
-F "asset_id=123,124,125"
```

### 36. Remove Assets from Album

```
POST /api/album/remove
```

**Description:** Removes one or more assets from an album. The assets are only removed from the album
but remain in the main library. This does not delete the assets themselves.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the album

```
album_id (integer, required): The album ID to remove assets from
asset_ids (string, required): Comma-separated list of asset IDs to remove
```

**Response:**
Success: "Photos removed from album successfully"
Error: "username not found" (404)

**Example:**

```
curl -X POST http://localhost:7251/api/album/remove \
-F "username=john_doe" \
-F "album_id=1" \
-F "asset_ids=123,124"
```

### 37. Delete Album

```
POST /api/album/delete
```

**Description:** Permanently deletes an album and all its associations. The assets within the album are
NOT deleted and remain in the main library. Only the album container and its asset associations are
removed.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the album
album_id (integer, required): The album ID to delete

**Response:**
Success: "Album deleted successfully"
Error: "username not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/album/delete \
-F "username=john_doe" \
-F "album_id=1"
```

### 38. Get Album Assets

```
GET /api/album/<username>/<album_id>
```

**Description:** Retrieves all assets within a specic album, grouped by creation date and ordered
chronologically. This provides the content for the album detail view.
**Method:** GET

**Path Parameters:**
username (string, required): The username who owns the album
album_id (integer, required): The album ID to retrieve

**Request Body:** None
**Response:**

```
[
[
"2024-06-15",
[
[123],
[124, null, "2:45"],
[125]
]
],
[
"2024-06-14",
[
[126]
]
]
]
```

**Example:**

```
curl http://localhost:7251/api/album/john_doe/1
```

### 39. Rename Album

```
POST /api/album/rename
```

**Description:** Changes the name of an existing album. This updates the album metadata while
preserving all asset associations and other album properties.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the album
album_id (integer, required): The album ID to rename
name (string, required): The new name for the album

**Response:**
Success: "Album renamed successfully"
Error: "username not found" (404) or "Bad request" (400)

**Example:**

```
curl -X POST http://localhost:7251/api/album/rename \
-F "username=john_doe" \
-F "album_id=1" \
-F "name=Hawaii Vacation"
```

### 40. Redate Album

```
POST /api/album/redate
```

**Description:** Updates the start date associated with an album. This is useful for organizing albums
chronologically and setting the time period the album represents.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username who owns the album
album_id (integer, required): The album ID to update
date (string, required): The new start date in YYYY-MM-DD format

**Response:**

```
Success: "Album redated successfully"
Error: "username not found" (404) or "Bad request" (400)
```

**Example:**

```
curl -X POST http://localhost:7251/api/album/redate \
-F "username=john_doe" \
-F "album_id=1" \
-F "date=2024-06-01"
```

## AUTO ALBUMS APIs

### 41. Get Auto Albums List

```
POST /api/list/autoalbums
```

**Description:** Retrieves automatically generated smart albums based on AI-detected content like Places
(beaches, mountains), Things (objects), and Documents (receipts, IDs). Each category shows albums
that have at least one matching asset along with a cover image.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose auto albums to retrieve

**Response:**

```
{
"Places": [
["Swimming", "123", "2024-06-15"],
["Mountains", "456", "2024-05-10"],
["Beach", "789", "2024-07-20"]
],
"Things": [
["Dogs", "234", "2024-04-12"],
["Cars", "567", "2024-03-08"]
],
"Documents": [
["Books", "890", "2024-02-15"],
```

```
["Receipts", "901", "2024-01-20"]
]
}
```

Note: Each entry contains [category_name, cover_asset_id, date]
**Example:**

```
curl -X POST http://localhost:7251/api/list/autoalbums \
-F "username=john_doe"
```

### 42. Get Auto Album Assets

```
GET /api/autoalbum/<username>/<auto_album_name>
```

**Description:** Retrieves a random preview image from assets matching a specic auto album category.
Auto albums are generated based on AI-detected tags like "Swimming", "Food", "Mountains", etc. The
endpoint returns a single representative image.
**Method:** GET

**Path Parameters:**
username (string, required): The username whose assets to query
auto_album_name (string, required): The name of the auto album (e.g., "Swimming", "Food",
"Mountains", "Books", "ID Cards", "Wedding", "Birthday", etc.)
**Request Body:** None
**Response:** Binary image data (image/webp)
**Supported Auto Album Names:**
Documents: Books, ID Cards, Note, Recipe & Menu, Text, Screenshots
Places: Swimming, Nightclub, Food, Animals, Train, Sunset, Wedding, Park, Airplane, Sky,
Waterfall, Cars, Temple, Birthday, Forests, Farms, Snow, Mountain, Hike
Things: Any detected object tag (dynamically generated)
**Example:**

```
curl http://localhost:7251/api/autoalbum/john_doe/Swimming --output swimm
```

## SEARCH APIs

### 43. Search Assets

```
POST /api/search
```

**Description:** Performs intelligent search across assets using natural language queries. Supports
searching by people names, AI-detected tags, favorites, blurry photos, and auto album categories. The
AI analyzes the query to extract relevant names and tags for accurate results.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose assets to search
query (string, required): The search query (e.g., "John at beach", "food photos", "mountains
sunset", "favourite", "blurry")
type (string, optional): Search type - "search" (default), "buttons" (for favorites/blurry), "auto
albums", or "albums"
**Query Examples:**
"John and Jane at beach" - Finds photos with both people at beach
"food" - Finds all food-related photos
"mountains sunset" - Finds sunset photos in mountains
"favourite" (with type="buttons") - Returns all liked assets
"blurry" (with type="buttons") - Returns blurry assets
"swimming" (with type="auto albums") - Returns swimming pool photos
**Response:**

```
[
[
"2024-06-15",
[
[123],
[124, "3:25"],
[125]
]
],
[
```

#### "2024-06-10",

#### [

#### [130]

#### ]

#### ]

#### ]

**Example:**

```
curl -X POST http://localhost:7251/api/search \
-F "username=john_doe" \
-F "query=John at beach" \
-F "type=search"
```

## STATISTICS APIs

### 44. Get Statistics

```
POST /api/stats
```

**Description:** Retrieves comprehensive statistics about the user's photo library including asset counts
by format, yearly distribution, top albums by size, top locations, and storage usage information. This
powers the statistics dashboard view.
**Method:** POST

**Parameters:** None
**Request Body (Form Data):**
username (string, required): The username whose statistics to retrieve

**Response:**

```
{
"image_counts": {
"jpg": 1250,
"png": 340,
"heic": 120
},
"video_counts": {
"mp4": 85,
```

```
"mov": 23
},
"yearly_counts": [
["2024", 450],
["2023", 680],
["2022", 320]
],
"top_albums": [
["Summer Vacation", 156],
["Wedding 2023", 98],
["Birthday Party", 45]
],
"top_locations": [
["Hawaii", 234],
["New York", 156],
["Paris", 89]
],
"used_storage": 45.67,
"total_storage": 500.0
}
```

Note: Storage values are in GB
**Example:**

```
curl -X POST http://localhost:7251/api/stats \
-F "username=john_doe"
```

## Response Format Notes

### Asset ID Arrays Format

Throughout the API, asset lists follow this convention:
[asset_id] - Image asset (single element)
[asset_id, null, "duration"] - Video asset (three elements with duration like "3:25")

### Date Format

```
Input dates: YYYY-MM-DD (e.g., "2024-03-15")
```

```
Output dates: YYYY-MM-DD or DD-MM-YYYY depending on endpoint
```

### Error Responses

Most endpoints return error messages in these formats:
String: "Error message"
JSON object: {"error": "Error message"}
HTTP status codes: 400 (Bad Request), 404 (Not Found)

## Common Request Patterns

### Form Data Requests

Most POST endpoints use multipart/form-data encoding:

```
curl -X POST {BASE_URL}/api/endpoint \
-F "param1=value1" \
-F "param2=value2"
```

### File Upload Requests

For uploading les:

```
curl -X POST {BASE_URL}/api/upload \
-F "username=john_doe" \
-F "asset=@/path/to/file.jpg"
```

### GET Requests

Simple GET requests:

```
curl {BASE_URL}/api/endpoint/param1/param2
```

## Notes

```
. User Authentication : Currently, username/password authentication is basic. Implement proper
session management in production.
. File Paths : The server stores les in a congured base path with structure:
{path}/{username}/{master|preview}/{year}/{month}/{day}/{asset_id}.
{ext}
. Background Processing : Asset uploads trigger background processing for preview generation,
face detection, blur detection, and tag extraction.
. Concurrent Requests : The API handles concurrent database access with retry logic for recursive
cursor usage.
. Duplicate Detection : Duplicates are detected by background processing comparing image
hashes.
. Face Recognition : Uses DeepFace or similar ML models for face detection and recognition.
. AI Tags : Uses Google Gemini AI and RAM (Recognize Anything Model) for automatic tag
generation.
```

## Getting Started

```
. Congure your BASE_URL:
const BASE_URL = "http://localhost:7251";
. Create a user:
curl -X POST {BASE_URL}/api/user/create \
-F "username=myuser" \
-F "password=mypass"
. Upload an asset:
curl -X POST {BASE_URL}/api/upload \
-F "username=myuser" \
-F "asset=@photo.jpg"
. List assets:
```

```
curl -X POST {BASE_URL}/api/list/general \
-F "username=myuser" \
-F "page=0"
```

**End of API Documentation**

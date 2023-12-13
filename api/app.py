from flask import Flask, jsonify, request, send_file, render_template

app = Flask(__name__)

# Error handler for 404 Not Found
@app.errorhandler(404)
def not_found_error(error):
    return jsonify({'error': 'Not Found'}), 404

# Error handler for 500 Internal Server Error
@app.errorhandler(500)
def internal_server_error(error):
    return jsonify({'error': 'Internal Server Error'}), 500

# hello world
@app.route('/')
def hello():
    return render_template('help.html')

# API to upload photos/videos
@app.route('/api/upload', methods=['POST'])
def upload():
    # Logic to handle photo/video uploaded in form
    username = request.form['username']
    print(username)
    photo_data = request.files['asset']
    print(photo_data.filename)

    allowed_extensions = {'png', 'jpg', 'jpeg', 'mp4'}
    if '.' in photo_data.filename and photo_data.filename.rsplit('.', 1)[1].lower() in allowed_extensions:
        # Save the photo/video to the database or storage
        # Update the sqlite database with the photo/video details

        # ...
        return jsonify({'message': 'Uploaded successfully'})
    else:
        return jsonify({'error': 'Invalid file type'}), 400

# API to delete a photo
@app.route('/api/delete/<int:photo_id>', methods=['DELETE'])
def delete_photo(photo_id):
    # Logic to delete the photo from the database or storage
    # ...
    if photo_id not in (1,2,3):
        return jsonify({'error': 'Photo not found'}), 404
    return jsonify({'message': 'Photo deleted successfully'})

# API to get a photo/video preview
@app.route('/api/preview/<int:photo_id>', methods=['GET'])
def preview_asset(photo_id):
    # Logic to get the preview photo/video from the database or storage
    # ...
    if photo_id not in (1,2,3):
        return jsonify({'error': 'Photo not found'}), 404
    #return a preview of the photo
    return send_file('test/preview.jpg', mimetype='image/jpg')

# API to get a photo/video original
@app.route('/api/asset/<int:photo_id>', methods=['GET'])
def get_asset(photo_id):
    # Logic to get the photo/video from the database or storage
    # ...
    if photo_id not in (1,2,3):
        return jsonify({'error': 'Photo not found'}), 404
    #return the photo
    return send_file('test/original.jpg', mimetype='image/jpg')

# API to get a list of photos/videos
@app.route('/api/list', methods=['GET'])
def get_list():
    # Logic to get the list of photos/videos from the database or storage
    # ...
    return jsonify({"26-10-2023":[1,2], "27-10-2023":[3]})

# get asset details
@app.route('/api/details/<int:photo_id>', methods=['GET'])
def get_details(photo_id):
    # Logic to get the photo/video from the database or storage
    # ...
    if photo_id not in (1,2,3):
        return jsonify({'error': 'Photo not found'}), 404
    #return the photo
    return jsonify({"People":[1,2,3], "tags":["blade", "close-up", "dew", "drop", "leaf", "grass", "green", "plant", "rain", "stem", "water", "water drop"], "date":"26-10-2023", "time":"12:00", "format":"JPG","MP":"16MP","width":1920,"height":1080,"size":"449 KB","location":None})

# API to get a list of faces
@app.route('/api/faces/<int:face_id>', methods=['GET'])
def get_faces(face_id):
    # Logic to get the list of faces from the database or storage
    # ...
    if face_id == 1:
        return jsonify({"name":"Meet","image":"https://images.rawpixel.com/image_800/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvMjc5LXBhaTE1NzktbmFtLmpwZw.jpg"})
    elif face_id == 2:
        return jsonify({"name":"Shravani","image":"https://storage.googleapis.com/pai-images/38c04881ea8946249365dd45ff67abbf.jpeg"})
    elif face_id == 3:
        return jsonify({"name":"Karan","image":"https://images.rawpixel.com/image_800/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvMjc5LXBhaTE1NzktbmFtLmpwZw.jpg"})
    else:
        return jsonify({'error': 'Photo not found'}), 404

# API to get a list of faces in a photo with coordinates
@app.route('/api/assetface/<int:asset>', methods=['GET'])
def get_assetface(asset):
    # Logic to get the list of faces from the database or storage
    # ...
    if asset not in (1,2,3):
        return jsonify({'error': 'Photo not found'}), 404
    #return the photo
    return jsonify([
        {"faceid":1, "x":10,"y":10,"w":100,"h":100},{"faceid":2, "x":200,"y":200,"w":100,"h":100},{"faceid":3, "x":300,"y":300,"w":100,"h":100}])   

if __name__ == '__main__':
    app.run()

# I think we dont need this ------------------- Down ones
# API to Make albums
@app.route('/api/album/create/<string:album_name>', methods=['POST'])
def create_album(album_name):
    # Logic to create album
    cursor.execute('''INSERT INTO album (name, uuid) VALUES (?, ?)''', (album_name, uuid.uuid4().hex))
    conn.commit()
    return jsonify('Album created successfully')

# API to List Albums
@app.route('/api/album/list', methods=['GET'])
def list_album():
    # Logic to list albums
    cursor.execute('''SELECT id, name, cover FROM album''')
    result = cursor.fetchall()
    formatted_result = [{"id":row[0], "name":row[1], "cover":row[2]} for row in result]
    return jsonify(formatted_result)

# API to Delete Albums
@app.route('/api/album/delete/<int:album_id>', methods=['DELETE'])
def delete_album(album_id):
    # Logic to delete album
    cursor.execute('''DELETE FROM album WHERE id = ?''', (album_id,))
    if cursor.rowcount == 0:
        return jsonify('Album not found'), 404
    conn.commit()
    return jsonify('Album deleted successfully')

# API to Add image to album
@app.route('/api/album/add/<int:album_id>/<int:asset_id>', methods=['POST'])
def add_to_album(album_id, asset_id):
    # Logic to add image to album
    cursor.execute('''INSERT INTO album_assets (album_id, asset_id) VALUES (?, ?)''', (album_id, asset_id))
    if cursor.rowcount == 0:
        return jsonify('Image not found'), 404
    # check if cover is null, if null set cover to asset_id
    cursor.execute('''UPDATE album SET cover = ? WHERE id = ? AND cover IS NULL''', (asset_id, album_id))
    conn.commit()

    return jsonify('Image added to album successfully')


# PENDING
# API to edit Album
@app.route('/api/album/edit/<int:album_id>', methods=['POST'])
def edit_album(album_id):
    # Logic to edit album
    name = request.form['name']
    location = request.form['location']
    start = request.form['start']
    end = request.form['end']
    cursor.execute('''UPDATE album SET name = ?, location = ?, start = ?, end = ? WHERE id = ?''', (name, location, start, end, album_id))
    if cursor.rowcount == 0:
        return jsonify('Album not found'), 404
    conn.commit()
    return jsonify('Album edited successfully')

# API to Remove image from album
@app.route('/api/album/remove/<int:album_id>/<int:asset_id>', methods=['DELETE'])
def remove_from_album(album_id, asset_id):
    # Logic to remove image from album
    cursor.execute('''DELETE FROM album_assets WHERE album_id = ? AND asset_id = ?''', (album_id, asset_id))
    if cursor.rowcount == 0:
        return jsonify('Image not found in album'), 404
    conn.commit()
    return jsonify('Image removed from album successfully')

# API to Get album details
@app.route('/api/album/details/<int:album_id>', methods=['GET'])
def get_album_details(album_id):
    # Logic to get album details
    cursor.execute('''SELECT name, cover, start, end, location FROM album WHERE id = ?''', (album_id,))
    if cursor.rowcount == 0:
        return jsonify('Album not found'), 404
    result = cursor.fetchone()
    
    cursor.execute('''SELECT DISTINCT face_id FROM asset_faces
                      INNER JOIN assets ON asset_faces.asset_id = assets.id
                      INNER JOIN album_assets ON assets.id = album_assets.asset_id
                      WHERE album_assets.album_id = ?''', (album_id,))
    people = [row[0] for row in cursor.fetchall()]
    
    formatted_result = {"name": result[0], "cover": result[1], "start": result[2], "end": result[3], "location": result[4], "people": people}
    return jsonify(formatted_result)

# API to Get album images
@app.route('/api/album/images/<int:album_id>', methods=['GET'])
def get_album_images(album_id):
    # Logic to get album images
    cursor.execute('''SELECT DATE(assets.created), asset_id FROM album_assets 
                      INNER JOIN assets ON album_assets.asset_id = assets.id
                      WHERE album_id = ?
                      ORDER BY DATE(assets.created) ASC''', (album_id,))
    if cursor.rowcount == 0:
        return jsonify('Album not found'), 404
    result = cursor.fetchall()
    formatted_result = {}
    for row in result:
        date = row[0]
        image_id = row[1]
        if date in formatted_result:
            formatted_result[date].append(image_id)
        else:
            formatted_result[date] = [image_id]
    return jsonify(formatted_result)

# API to Get album cover
@app.route('/api/album/cover/<int:album_id>', methods=['GET'])
def get_album_cover(album_id):
    # Logic to get album cover
    cursor.execute('''SELECT cover FROM album WHERE id = ?''', (album_id,))
    if cursor.rowcount == 0:
        return jsonify('Album not found'), 404
    cover_id = cursor.fetchone()[0]
    if cover_id is None:
        # Check if there are any images in the album
        cursor.execute('''SELECT asset_id FROM album_assets WHERE album_id = ?''', (album_id,))
        if cursor.rowcount > 0:
            # Set the first image as the album cover
            first_image_id = cursor.fetchone()[0]
            cursor.execute('''UPDATE album SET cover = ? WHERE id = ?''', (first_image_id, album_id))
            conn.commit()
            cursor.execute('''SELECT created, format FROM assets WHERE id = ?''', (first_image_id,))
            result = cursor.fetchone()
            date_time = result[0]
            image_format = result[1]
            # convert date_time to datetime object
            date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
            return send_file(f'master/{date_time.year}/{date_time.month}/{date_time.day}/{first_image_id}.{image_format}', mimetype=f'image/{image_format}')
        else:
            # Return default cover image
            return send_file('data/preview/defaultalbum.webp', mimetype='image/webp')
    else:
        cursor.execute('''SELECT asset_id FROM album_assets WHERE album_id = ? AND asset_id = ?''', (album_id, cover_id))
        if cursor.rowcount <= 0:
            # Check if there are any images in the album
            cursor.execute('''SELECT asset_id FROM album_assets WHERE album_id = ?''', (album_id,))
            if cursor.rowcount > 0:
                # Set the first image as the album cover
                first_image_id = cursor.fetchone()[0]
                cursor.execute('''UPDATE album SET cover = ? WHERE id = ?''', (first_image_id, album_id))
                conn.commit()
                cursor.execute('''SELECT created, format FROM assets WHERE id = ?''', (first_image_id,))
                result = cursor.fetchone()
                date_time = result[0]
                image_format = result[1]
                # convert date_time to datetime object
                date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
                return send_file(f'master/{date_time.year}/{date_time.month}/{date_time.day}/{first_image_id}.{image_format}', mimetype=f'image/{image_format}')
            else:
                # Return default cover image
                return send_file('data/preview/defaultalbum.webp', mimetype='image/webp')
        cursor.execute('''SELECT created, format FROM assets WHERE id = ?''', (cover_id,))
        result = cursor.fetchone()
        date_time = result[0]
        image_format = result[1]
        # convert date_time to datetime object
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
        return send_file(f'master/{date_time.year}/{date_time.month}/{date_time.day}/{cover_id}.{image_format}', mimetype=f'image/{image_format}')



# obselete
def background_tasks(connection):    
    threading.Thread(target=background_funs.trainModel, args=(r"data\training",), daemon=True).start()
    cnt = 0
    while True:
        if not os.path.exists('temp'):os.makedirs('temp')
        if(os.listdir('temp') == []):
            cnt+=1
        else:
            cnt = 0
        if(cnt==60):
            # find duplicates
            print("time to find duplicates")
            # os.system('python duplicates.py')
            # background_funs.find_similar_images("master",connection)
            time.sleep(5)
            continue
        for asset in os.listdir('temp'):

            image_id = asset.rsplit('.')[0]
            print(image_id)

            # get the tags - USE PYTHON 3.8.10 or 3.10.0
            tagsThread = threading.Thread(target=background_funs.tagImage, args=("temp/"+asset, image_id, connection), daemon=False)
            tagsThread.start()

            # Get year month date from image created exif data
            date_time = None

            img = Image.open("temp/"+asset)
            exif_data = img.getexif()
            for tag_id in exif_data:
                tag = ExifTags.TAGS.get(tag_id, tag_id)
                data = exif_data.get(tag_id)

                # get the date and time from exif data using tag
                if tag == 'DateTimeOriginal':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'DateTimeDigitized':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'DateTime':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'GPSInfo':  # TODO: get location from GPSInfo
                    pass
            
            img.close()

            # get the faces
            train = background_funs.recogniseFaces("temp/"+asset, image_id, connection)
            if train:
                threading.Thread(target=background_funs.trainModel, args=(r"data\training",), daemon=False).start()

            # # get the blurry
            background_funs.checkBlur("temp/"+asset, image_id, connection)
            tagsThread.join()

            cursor = connection.cursor()
            if date_time is not None:
                cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (date_time, image_id))
            else:
                cursor.execute("SELECT created FROM assets WHERE id = ?", (image_id,))
                date_time = cursor.fetchone()[0]
                date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')

            # save the image with preview
            background_funs.saveImage("temp/"+asset, image_id, asset.rsplit(".")[-1], False, "master", "preview", date_time.year, date_time.month, date_time.day)

            connection.commit()
            
        time.sleep(5)



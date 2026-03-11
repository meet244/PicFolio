import difPy
import sqlite3
import json
import os
import user_store

def read_config():
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"path": ""}
        with open('config.json', 'w') as f:
            json.dump(config, f)
    config.setdefault('path', "")
    print("Config loaded")
    return config


def list_users(config):
    if not config.get('path'):
        return []
    try:
        return user_store.list_users(config['path'])
    except Exception as exc:
        print(f"Unable to load users for duplicates scan: {exc}")
        return []

if __name__ == "__main__":

    config = None

    config = read_config()

    for u in list_users(config):

        try:
            dif = difPy.build(f"{config['path']}/{u}/master/", in_folder=True, recursive=True, show_progress=False, logs=False)
        except Exception as e:
            print(e)
            continue
        search = difPy.search(dif, 'similar')
        print(search.result)
        print(search.lower_quality)

        output = search.result or {}
        lower = search.lower_quality or []

        def normalize_lower_set(lower_quality):
            if isinstance(lower_quality, dict):
                lower_iterable = lower_quality.get('lower_quality', [])
            else:
                lower_iterable = lower_quality
            return {str(item) for item in lower_iterable}

        def iter_match_pairs(result):
            if not isinstance(result, dict):
                return
            for value in result.values():
                if not isinstance(value, dict):
                    continue
                if 'contents' in value:  # legacy difPy structure
                    for entry in value['contents'].values():
                        base = entry.get('location')
                        matches = entry.get('matches', {})
                        for match in matches.values():
                            yield base, match.get('location')
                else:
                    for base, matches in value.items():
                        if isinstance(matches, dict):
                            for match in matches.values():
                                if isinstance(match, dict):
                                    yield base, match.get('location')
                        elif isinstance(matches, list):
                            for match in matches:
                                if isinstance(match, (list, tuple)) and match:
                                    yield base, match[0]

        lower_set = normalize_lower_set(lower)

        def asset_is_deleted(cur, asset_id):
            try:
                cur.execute("SELECT deleted FROM assets WHERE id = ?", (asset_id,))
            except sqlite3.Error as err:
                print(f"Failed to read deleted flag for asset {asset_id}: {err}")
                return False

            row = cur.fetchone()
            if not row:
                return False

            deleted_val = row[0]
            return deleted_val not in (None, 0, "0")

        connection = sqlite3.connect(f'{config["path"]}/{u}/data.db', check_same_thread=False)
        cursor = connection.cursor()

        for img1_path, img2_path in iter_match_pairs(output):
            if not img1_path or not img2_path:
                continue

            img1_pref = str(img1_path)
            img2_pref = str(img2_path)

            if img1_pref in lower_set and img2_pref not in lower_set:
                # swap the images
                img1_pref, img2_pref = img2_pref, img1_pref

            asset1 = os.path.splitext(os.path.basename(img1_pref))[0]
            asset2 = os.path.splitext(os.path.basename(img2_pref))[0]

            if not asset1 or not asset2:
                continue

            try:
                asset1_id = int(asset1)
                asset2_id = int(asset2)
            except ValueError:
                print(f"Skipping duplicate pair with non-numeric ids: {asset1}, {asset2}")
                continue

            if asset_is_deleted(cursor, asset1_id) or asset_is_deleted(cursor, asset2_id):
                print(f"Skipping deleted duplicate pair: {asset1_id}, {asset2_id}")
                continue

            print(img1_pref)
            print(img2_pref)
            print(asset1)
            print(asset2)

            try:
                cursor.execute("INSERT INTO duplicates (asset_id, asset_id2) VALUES (?, ?)", (asset1_id, asset2_id))
            except Exception as e:
                if 'UNIQUE constraint failed' in str(e):
                    pass
                else:
                    print(e)

        connection.commit()
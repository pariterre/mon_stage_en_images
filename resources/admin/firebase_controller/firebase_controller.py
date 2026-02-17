import json
from pathlib import Path

import firebase_admin
from firebase_admin import db, storage
import pandas


class FirebaseController:
    def __init__(self, certificate_path: Path):
        self._certificate_path = certificate_path
        self._database_url = "https://monstageenimages-default-rtdb.firebaseio.com"
        self._bucket_url = "monstageenimages.appspot.com"

        self._initialize_database()

    def database_as_json(
        self, save_folder: Path, force_download: bool = False, download_storage: bool = True
    ) -> pandas.DataFrame:
        save_filepath: Path = Path(save_folder) / "firebase_export.json"

        if not save_filepath.exists() or force_download:
            # Fetch data
            data = db.reference("/v0_1_0").get()

            # Save data to JSON file
            save_filepath.parent.mkdir(parents=True, exist_ok=True)
            with open(save_filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)

        if download_storage:
            self._list_and_download_files(save_folder, force_download)

        return pandas.read_json(save_filepath)

    def _list_and_download_files(self, save_folder: Path, force_download: bool = False):
        save_folder: Path = Path(save_folder) / "storage"

        if not save_folder.exists() or force_download:
            # Download all files
            save_folder.mkdir(parents=True, exist_ok=True)
            print("Downloading all the files, this may take a while...")
            for blob in storage.bucket().list_blobs():
                file_path: Path = save_folder / blob.name
                file_path.parent.mkdir(parents=True, exist_ok=True)
                blob.download_to_filename(str(file_path))

    def _initialize_database(self):
        # Initialize Firebase Admin SDK
        cred = firebase_admin.credentials.Certificate(self._certificate_path)
        firebase_admin.initialize_app(
            cred,
            {"databaseURL": self._database_url, "storageBucket": self._bucket_url},
        )

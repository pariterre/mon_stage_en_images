import os
from pathlib import Path

from firebase_controller import FirebaseController


def main():
    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-3a91847821.json",
        temporary_folder=Path(__file__).parent / "export",
        force_refresh=False,
        use_emulator=os.getenv("USE_DATABASE_EMULATOR", "false").lower() == "true",
    )
    controller.set_required_app_version()


if __name__ == "__main__":
    main()

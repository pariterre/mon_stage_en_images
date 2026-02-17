from pathlib import Path

from firebase_controller import FirebaseController


def main():
    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-26b3311e20.json"
    )


if __name__ == "__main__":
    main()

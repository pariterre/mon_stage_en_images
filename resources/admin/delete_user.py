import os
from pathlib import Path

from firebase_controller import FirebaseController


def main():
    user_id = input("Enter the id of the user to delete, leave empty to cancel: ")
    if user_id is None or user_id == "":
        print("No user id provided, cancelling.")
        return

    confirm = input(
        f"Are you sure you want to delete the user with id {user_id}? This action cannot be undone. (y/[n]) "
    )
    if confirm.lower() != "y":
        print("User deletion cancelled.")
        return

    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-3a91847821.json",
        temporary_folder=Path(__file__).parent / "export",
        force_refresh=os.getenv("FORCE_DATABASE_FETCHING", "false").lower() == "true",
        use_emulator=os.getenv("USE_DATABASE_EMULATOR", "false").lower() == "true",
    )
    controller.delete_user(user_id=user_id)


if __name__ == "__main__":
    main()

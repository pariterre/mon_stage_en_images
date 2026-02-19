import os
from pathlib import Path
import re

from firebase_controller import FirebaseController, UserModel


def main():
    save_folder = Path(__file__).parent / "export"
    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-3a91847821.json",
        temporary_folder=save_folder,
        force_refresh=os.getenv("FORCE_DATABASE_FETCHING", "false").lower() == "true",
        use_emulator=os.getenv("USE_DATABASE_EMULATOR", "false").lower() == "true",
    )

    for uid in controller.authenticated_users.keys():
        user = controller.user(uid)
        if user is not None:
            continue

        email = controller.authenticated_users[uid]
        # Try to extract a name from the email
        match = re.match(r"^(.*)[\.](.*)@.*$", email)
        if match is None:
            user_model = UserModel.empty(id=uid, email=email)
        else:
            groups = match.groups()
            if len(groups) != 2:
                user_model = UserModel.empty(id=uid, email=email)
            else:
                first_name = groups[0].capitalize()
                last_name = groups[1].capitalize()
                user_model = UserModel(id=uid, first_name=first_name, last_name=last_name, email=email)

        controller.set_user(user_model.serialized)


if __name__ == "__main__":
    main()

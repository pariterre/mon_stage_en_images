from datetime import datetime
import random


class UserModel:
    def __init__(
        self,
        id: str,
        first_name: str,
        last_name: str,
        email: str,
        avatar: str = None,
        student_notes: dict | None = None,
        tokens: dict | None = None,
        terms_and_services_accepted: bool = False,
        irsst_page_seen: bool = False,
        has_seen_student_onboarding: bool = False,
        has_seen_teacher_onboarding: bool = False,
        creation_date: datetime = None,
    ):
        self._id = id
        self._first_name = first_name
        self._last_name = last_name
        self._avatar = random.choice(_available_avatars) if avatar is None else avatar
        self._creation_date = datetime.now() if creation_date is None else creation_date
        self._email = email

        self._student_notes = {} if student_notes is None else student_notes
        self._tokens = {} if tokens is None else tokens

        self._change_password = False
        self._irsst_page_seen = irsst_page_seen
        self._has_seen_student_onboarding = has_seen_student_onboarding
        self._has_seen_teacher_onboarding = has_seen_teacher_onboarding
        self._terms_and_services_accepted = terms_and_services_accepted

    @classmethod
    def empty(cls, id: str, email: str) -> "UserModel":
        return cls(id=id, first_name="Élève", last_name="Anonyme", email=email)

    @classmethod
    def from_serialized(cls, data: dict) -> "UserModel":
        return cls(
            id=data["id"],
            first_name=data["firstName"],
            last_name=data["lastName"],
            email=data["email"],
            avatar=data["avatar"],
            student_notes=data["studentNotes"] if "studentNotes" in data else None,
            tokens=data["tokens"] if "tokens" in data else {},
            terms_and_services_accepted=(
                data["termsAndServicesAccepted"] if "termsAndServicesAccepted" in data else True
            ),
            irsst_page_seen=data["irsstPageSeen"] if "irsstPageSeen" in data else True,
            has_seen_student_onboarding=(
                data["hasSeenStudentOnboarding"] if "hasSeenStudentOnboarding" in data else True
            ),
            has_seen_teacher_onboarding=(
                data["hasSeenTeacherOnboarding"] if "hasSeenTeacherOnboarding" in data else True
            ),
            creation_date=datetime.fromisoformat(data["creationDate"]) if "creationDate" in data else datetime.now(),
        )

    @property
    def serialized(self) -> dict:
        return {
            "id": self._id,
            "firstName": self._first_name,
            "lastName": self._last_name,
            "avatar": self._avatar,
            "creationDate": f"{self._creation_date:%Y-%m-%d}T{self._creation_date:%H:%M:%S.%f}",
            "email": self._email,
            "studentNotes": self._student_notes,
            "tokens": self._tokens,
            "changePassword": self._change_password,
            "termsAndServicesAccepted": self._terms_and_services_accepted,
            "irsstPageSeen": self._irsst_page_seen,
            "hasSeenStudentOnboarding": self._has_seen_student_onboarding,
            "hasSeenTeacherOnboarding": self._has_seen_teacher_onboarding,
        }


_available_avatars = [
    # Faces
    "🐶",
    "🐺",
    "🐱",
    "🦁",
    "🐯",
    "🐴",
    "🦄",
    "🐮",
    "🐷",
    "🐽",
    "🐸",
    "🐵",
    "🙈",
    "🙉",
    "🙊",
    # Pets & farm
    "🐹",
    "🐰",
    "🦊",
    "🐻",
    "🐼",
    "🐻‍❄️",
    "🐨",
    "🐮",
    "🐔",
    "🐤",
    "🐥",
    "🐣",
    "🐧",
    "🦆",
    "🦅",
    "🦉",
    "🦇",
    # Wild animals
    "🐗",
    "🐴",
    "🦓",
    "🦍",
    "🦧",
    "🐘",
    "🦛",
    "🦏",
    "🦒",
    "🐪",
    "🐫",
    "🦙",
    "🦌",
    "🦬",
    # Sea life
    "🐶",
    "🐱",
    "🐭",
    "🐹",
    "🐰",
    "🦊",
    "🐻",
    "🐼",
    "🐨",
    "🐟",
    "🐠",
    "🐡",
    "🦈",
    "🐬",
    "🐳",
    "🐋",
    "🦭",
    "🐙",
    "🦑",
    "🦀",
    "🦞",
    "🦐",
    # Reptiles & insects
    "🐍",
    "🦎",
    "🐢",
    "🐊",
    "🦖",
    "🦕",
    "🐝",
    "🐞",
    "🦋",
    "🐛",
    "🪲",
    "🪳",
    "🕷️",
    "🦂",
    # More birds
    "🦃",
    "🦚",
    "🦜",
    "🦢",
    "🦩",
    "🕊️",
    "🐦",
    # Extras
    "🦘",
    "🦥",
    "🦦",
    "🦨",
    "🦡",
    "🐿️",
    "🦔",
]

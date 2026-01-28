# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import db_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, db, messaging

# For cost control, you can set the maximum number of containers that can be
# running at the same time. This helps mitigate the impact of unexpected
# traffic spikes by instead downgrading performance. This limit is a per-function
# limit. You can override the limit for each function using the max_instances
# parameter in the decorator, e.g. @https_fn.on_request(max_instances=5).
set_global_options(max_instances=10)

initialize_app()


def _cleanup_invalid_tokens(tokens: list[str], response: messaging.BatchResponse, receiver_id: str) -> None:
    ref = db.reference(f"/v0_1_0/users/{receiver_id}/pushNotificationsTokens")

    for idx, resp in enumerate(response.responses):
        if not resp.success:
            error = resp.exception
            if error.code in ("registration-token-not-registered", "invalid-argument"):
                token = tokens[idx]

                # Works for both list and map storage
                ref.child(token).delete()


def _send_notification(receiver_id: str, title: str, body: str) -> None:
    fcm_tokens = db.reference(f"/v0_1_0/users/{receiver_id}/pushNotificationsTokens").get()

    if not fcm_tokens:
        return

    # Normalize tokens to a list
    if isinstance(fcm_tokens, dict):
        fcm_tokens = list(fcm_tokens.keys())
    elif isinstance(fcm_tokens, list):
        fcm_tokens = fcm_tokens
    else:
        return
    if not fcm_tokens:
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        tokens=fcm_tokens,
    )

    response = messaging.send_each_for_multicast(message)

    # Optional cleanup of invalid tokens
    if response.failure_count > 0:
        _cleanup_invalid_tokens(fcm_tokens, response, receiver_id)


@db_fn.on_value_created(reference="/v0_1_0/answers/{token}/{studentId}/{questionId}/discussion/{responseId}")
def notify_on_new_message(event: db_fn.Event[db_fn.DataSnapshot]) -> None:
    """
    Sends a notification when a new discussion message is created
    under a student's answer to a question.
    """
    params = event.params
    data = event.data.val()

    # Read the sender of the current message
    sender_id = data.get("creatorId")
    if not sender_id:
        return

    # Some aliases for easier access
    token = params["token"]
    student_id = params["studentId"]
    question_id = params["questionId"]
    if not token or not student_id or not question_id:
        return

    # Read the teacher id from parent node
    teacher_id = db.reference(f"/v0_1_0/answers/{token}/{student_id}/{question_id}/createdById").get()
    if not teacher_id:
        return

    # Decide notification recipient
    if sender_id == student_id:
        receiver_id = teacher_id
        student = db.reference(f"/v0_1_0/users/{student_id}").get()
        avatar = student.get("avatar")
        first_name = student.get("firstName")
        last_name = student.get("lastName")
        body_message = f"{first_name} {last_name} ({avatar}) vous a envoyé un message."
    elif sender_id == teacher_id:
        receiver_id = student_id
        body_message = "Ton enseignant.e a envoyé un message!"
    else:
        return

    # Send notification
    _send_notification(receiver_id=receiver_id, title="Nouvelle réponse", body=body_message)

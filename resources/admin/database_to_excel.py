from pathlib import Path
import pandas as pd

from firebase_controller import FirebaseController


def main():
    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-3a91847821.json"
    )

    save_folder = Path(__file__).parent / "export"

    title_timestamp = "Timestamp"
    title_id_student = "Id élève"
    title_id_teacher = "Id enseignant\u00b7e"
    title_first_name_teacher = "Prénom enseignant\u00b7e"
    title_last_name_teacher = "Nom enseignant\u00b7e"
    title_id_question = "Id question"
    title_metier = "MÉTIER"
    title_id_answer = "Id réponse"
    title_content_type = "Question/Répondant"
    title_content_text = "Text"

    output = pd.DataFrame(
        columns=[
            title_timestamp,
            title_id_student,
            title_id_teacher,
            title_first_name_teacher,
            title_last_name_teacher,
            title_id_question,
            title_metier,
            title_id_answer,
            title_content_type,
            title_content_text,
        ]
    )

    db = controller.database_as_pandas(save_folder=save_folder, force_download=True, download_storage=True)

    # Extract data from the databse
    users = {user["id"]: user for user in db["users"] if isinstance(user, dict) and "firstName" in user}
    tokenized_answers = db["answers"]
    questions = db["questions"]

    teacher_ids = {
        token["metadata"]["createdBy"]: token["connectedUsers"].keys()
        for token in db["tokens"]
        if isinstance(token, dict) and "connectedUsers" in token
    }
    for teacher_id in teacher_ids.keys():
        teacher = users[teacher_id]

        student_ids = teacher_ids[teacher_id]
        for student_id in student_ids:
            student = users[student_id]
            tokens = list(student["tokens"]["connected"].keys())
            if len(tokens) != 1:
                raise NotImplementedError("Connected to more than one tokens is not supported yet")
            token = tokens[0]

            teacher_first_name = teacher["firstName"]
            teacher_last_name = teacher["lastName"]

            answer_ids = tokenized_answers[token][student_id]
            for question_id in answer_ids:
                if question_id == "id" or question_id not in questions[teacher_id]:
                    continue

                question = questions[teacher_id][question_id]
                metier = "MÉTIER"[question["section"]]
                output.loc[len(output)] = [
                    "",
                    student_id,
                    teacher_id,
                    teacher_first_name,
                    teacher_last_name,
                    question_id,
                    metier,
                    "",
                    "Question",
                    question["text"],
                ]

                if "discussion" not in answer_ids[question_id]:
                    continue

                for discussion_id in answer_ids[question_id]["discussion"]:
                    tp = answer_ids[question_id]["discussion"][discussion_id]
                    time_stamp = pd.to_datetime(tp["creationTimeStamp"], unit="us").strftime("%Y-%m-%d %H:%M:%S")
                    if not time_stamp:
                        print("Ccouou")
                    author = "student" if tp["creatorId"] == student_id else "teacher"
                    content = tp["text"]

                    output.loc[len(output)] = [
                        time_stamp,
                        student_id,
                        teacher_id,
                        teacher_first_name,
                        teacher_last_name,
                        question_id,
                        metier,
                        discussion_id,
                        author,
                        content,
                    ]

    # Sort and save the output
    output = output.sort_values(
        by=[title_last_name_teacher, title_first_name_teacher, title_id_student, title_id_question, title_timestamp]
    )
    output.to_excel(save_folder / "output.xlsx", index=False)


if __name__ == "__main__":
    main()

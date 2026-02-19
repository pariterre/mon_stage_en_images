import os
from pathlib import Path
import pandas as pd

from firebase_controller import FirebaseController


def main():
    save_folder = Path(__file__).parent / "export"
    controller = FirebaseController(
        certificate_path=Path(__file__).parent / "monstageenimages-firebase-adminsdk-1owio-3a91847821.json",
        temporary_folder=save_folder,
        force_refresh=os.getenv("FORCE_DATABASE_FETCHING", "false").lower() == "true",
        use_emulator=os.getenv("USE_DATABASE_EMULATOR", "false").lower() == "true",
    )
    controller.download_storage(force_download=os.getenv("FORCE_DATABASE_FETCHING", "false").lower() == "true")

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

    for teaching_token in controller.teaching_tokens:
        teacher_id = controller.teacher_id(teaching_token=teaching_token)
        if teacher_id is None:
            continue
        teacher = controller.user(user_id=teacher_id)

        student_ids = controller.student_ids(teaching_token=teaching_token)
        for student_id in student_ids:
            student = controller.user(user_id=student_id)
            tokens = list(student["tokens"]["connected"].keys())
            if len(tokens) != 1:
                raise NotImplementedError("Connected to more than one tokens is not supported yet")
            token = tokens[0]

            teacher_first_name = teacher["firstName"]
            teacher_last_name = teacher["lastName"]

            student_answers = controller.answers(teaching_token=token, student_id=student_id)
            for question_id in student_answers:
                question = controller.question(teacher_id=teacher_id, question_id=question_id)
                if question is None:
                    continue

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

                if "discussion" not in student_answers[question_id]:
                    continue

                for discussion_id in student_answers[question_id]["discussion"]:
                    tp = student_answers[question_id]["discussion"][discussion_id]
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

class_name LessonTalk
extends Interactable
## Talking to Enea starts a lesson (82) while one is available.

var available: bool = true


func can_use() -> bool:
	return available

class_name QuestDef
extends Definition
## A quest as data. Phase-3 model: count occurrences of one EventBus topic.
## (Multi-objective quests, rewards, and chains arrive when a game needs
## them — P6. The pattern to extend is: conditions = topics + counts.)

@export var title: String = ""
## EventBus topic whose publications advance this quest.
@export var completion_topic: StringName = &""
@export var required_count: int = 1

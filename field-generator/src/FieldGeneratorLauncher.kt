import tornadofx.launch

fun main(args: Array<String>) {
    launch<FieldGenerator>("{\"newFieldName\": \"trial_type\", \"eventFields\": {\"type\": [\"square\", \"rt\"], \"position\": [\"1\", \"2\"], \"test\": [\"square\", \"rt\"], \"test1\": [\"1\", \"2\"]}}")
}
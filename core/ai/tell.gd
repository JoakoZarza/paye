class_name Tell
extends RefCounted
## Pista que el dealer deja ver después de una decisión importante.

## &"strong" o &"weak": lo que la pista aparenta, no necesariamente la verdad.
var category: StringName
var text_key: StringName
## &"calm", &"smug", &"nervous" o &"angry".
var icon: StringName
var honest: bool

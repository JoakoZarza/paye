class_name TableRules
extends RefCounted
## Banderas de reglas que los amuletos y los mazos cambian y que la mesa consulta.

var cigarette := false
## Probabilidad de que el Cigarrillo frene un pedido de mostrar (según su nivel).
var cigarette_chance := 0.5
var skip_next_show := false
var force_accept_next_call := false
## Facón III: además obliga a querer la subida siguiente.
var force_accept_extra := 0
## Espejo y Cartas marcadas mejorados.
var mirror_risk_multiplier := 1.0
var marked_step_multiplier := 1.0
var dealer_budget_multiplier := 1


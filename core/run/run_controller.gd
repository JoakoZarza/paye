class_name RunController
extends RefCounted
## Orquesta una run para las pantallas: bar, entrada, partido, premio, tienda,
## la cuenta final y el después. Emite eventos como el resto del núcleo.
## Ver DISENO §6 y §7.

enum Phase { BAR, MATCH, SHOP, BILL_HAND, FREE, DEAD, RETIRED, CONDEMNED }

const ENDED: Array[Phase] = [Phase.DEAD, Phase.RETIRED, Phase.CONDEMNED]
const PLAYER := 0
const DEALER := 1

var economy: Economy
var meta: MetaState
var phase: Phase = Phase.BAR
var state: RunState
var shop: Shop
## Amuletos y mesa del partido en curso.
var systems: AmuletSystem

var _meta_path: String
var _rng: RandomNumberGenerator
var _catalog_data: Dictionary
var _catalog: RivalCatalog
## Lo que faltaba pagar al empezar la mano contra el Gualicho.
var _bill_missing: int = 0
## Te pescaron haciendo trampa en el último partido: el rival siguiente lo sabe.
var _gossip := false
var _defs: Dictionary
var _decks: Dictionary
var _legacy_snapshot: Array[StringName] = []


func _init(p_economy: Economy, p_meta: MetaState, p_seed: int, p_meta_path: String = MetaState.DEFAULT_PATH) -> void:
	economy = p_economy
	meta = p_meta
	_meta_path = p_meta_path
	_rng = RandomNumberGenerator.new()
	_rng.seed = p_seed
	_catalog_data = RivalProfile.load_catalog()
	_defs = AmuletDef.load_all()
	_decks = RunDeck.load_all()
	shop = Shop.new(economy, _defs, _child_rng())


func start_run(deck_id: StringName) -> Array[GameEvent]:
	if state != null and not phase in ENDED:
		return [_illegal()]
	# Una run que quedó abierta (se cerró el juego) cuenta como jugada; su fiado ya
	# quedó guardado como deuda en el último punto de control.
	if meta.run_in_progress:
		meta.runs_played += 1
	state = RunState.new()
	state.money = economy.start_money
	state.debt = meta.debt
	state.deck = _decks[deck_id]
	_catalog = RivalCatalog.new(_catalog_data, _child_rng())
	var legacy := meta.legacy
	if legacy != &"" and _defs.has(legacy):
		state.loadout.equip(_defs[legacy])
		state.paid_for[legacy] = 0
	# El legado se consume al empezar: guardarlo ya evita recuperarlo cerrando el juego.
	meta.legacy = &""
	phase = Phase.BAR
	_checkpoint()
	return [GameEvent.make(&"run_started", {"money": state.money, "debt": state.debt, "legacy": legacy, "deck": deck_id})]


## La versión de cada ronda la eligió la semilla al empezar la run.
func rival_for(round: int) -> RivalProfile:
	return _catalog.rival_for(round) if _catalog != null else null


func enter_match() -> Array[GameEvent]:
	if state == null or phase != Phase.BAR:
		return [_illegal()]
	var entry := economy.entry(state.round)
	if not state.pay_entry(economy):
		return die()
	var rival := rival_for(state.round)
	_open_table(rival, economy.target_points(state.round))
	var greed := _warn_the_sins(rival, entry)
	phase = Phase.MATCH
	return [GameEvent.make(&"entry_paid", {
		"entry": entry, "tip": state.last_tip, "rival": rival.id, "sin": rival.sin, "final": economy.is_final(state.round),
		"target": economy.target_points(state.round), "round": state.round, "greed_cheats": greed,
	})]


## Los pecados se conocen (DISENO §5.4.1): el chisme sube la sospecha y la plata
## que llevás les da trampas de más. Devuelve cuántas trampas extra tiene el rival.
func _warn_the_sins(rival: RivalProfile, entry: int) -> int:
	var brain := table().brain
	if _gossip:
		brain.mood.suspicion = clampf(brain.mood.suspicion + economy.gossip_suspicion, 0.0, 1.0)
		_gossip = false
	if rival.sin == RivalCatalog.ALMA or rival.sin == RivalCatalog.GUALICHO or entry <= 0:
		return 0
	var extra := mini(economy.greed_max_extra, state.money / (economy.greed_entries_per_cheat * entry))
	brain.cheat_budget += extra
	return extra


func _open_table(rival: RivalProfile, target: int) -> void:
	var m := TrucoMatch.new(target, _child_rng())
	var table := CheatTable.new(m, DealerBrain.new(rival, _child_rng()), DEALER, _child_rng())
	state.deck.apply_to(table.rules)
	systems = AmuletSystem.new(table, state.loadout, _child_rng())
	systems.start_match()


func finish_match() -> Array[GameEvent]:
	if phase != Phase.MATCH or table().truco_match.winner() == -1:
		return [_illegal()]
	var t := table()
	if t.truco_match.winner() != PLAYER:
		return die()
	_gossip = t.player_cheats_caught > 0
	var prize := Prize.compute(economy.base_prize(state.round), t.truco_match.scores[DEALER],
		t.player_cheats_used, t.player_cheats_caught, t.player_called_envido,
		state.loadout, state.deck, economy, economy.is_final(state.round))
	var final := economy.is_final(state.round)
	var paid := state.collect_prize(prize["total"], economy, final)
	var events: Array[GameEvent] = [GameEvent.make(&"prize_paid", {
		"total": prize["total"], "multipliers": prize["multipliers"], "money": state.money,
		"retained": paid["retained"]})]
	if final:
		events.append_array(_settle_bill())
		return events
	phase = Phase.SHOP
	# Después de cada pecado, tienda especial (DISENO §6).
	shop.open(state, rival_for(state.round).sin != RivalCatalog.ALMA)
	_checkpoint()
	return events


## La cuenta del bar: con plata, después vendiendo amuletos y si no alcanza,
## una mano contra el Gualicho (Plan 5b, decisión 5).
func _settle_bill() -> Array[GameEvent]:
	var bill := state.bill(economy)
	var events: Array[GameEvent] = []
	if state.money < bill:
		var ids := _equipped_ids()
		if not ids.is_empty():
			var amount := 0
			for id in ids:
				amount += economy.sell_value(state.paid_for.get(id, 0))
				state.loadout.unequip(id)
				state.paid_for.erase(id)
			state.money += amount
			events.append(GameEvent.make(&"bill_amulets_sold", {"amount": amount, "ids": ids}))
	if state.money >= bill:
		state.money -= bill
		_bill_settled()
		events.append(GameEvent.make(&"bill_paid", {"bill": bill, "left": state.money}))
		return events
	_bill_missing = bill - state.money
	# Todo lo que tenías ya es del bar; si abandonás o perdés, debés lo que faltaba.
	state.money = 0
	state.fiado = 0
	state.debt = _bill_missing
	_open_table(_catalog.gualicho(), economy.target_points(state.round))
	phase = Phase.BILL_HAND
	_checkpoint()
	events.append(GameEvent.make(&"bill_hand_started", {"missing": _bill_missing}))
	return events


func _bill_settled() -> void:
	state.fiado = 0
	state.debt = 0
	phase = Phase.FREE
	_checkpoint()


## Llamar cuando terminó la mano contra el Gualicho. Gana quien sumó más puntos
## en esa mano; el empate es del Gualicho.
func finish_bill_hand() -> Array[GameEvent]:
	if phase != Phase.BILL_HAND:
		return [_illegal()]
	var m := table().truco_match
	if m.hand == null or (not m.hand.is_over() and m.winner() == -1):
		return [_illegal()]
	if m.scores[PLAYER] > m.scores[DEALER]:
		_bill_settled()
		return [GameEvent.make(&"bill_hand_won", {"missing": _bill_missing})]
	var events: Array[GameEvent] = [GameEvent.make(&"bill_hand_lost", {"missing": _bill_missing})]
	events.append_array(die())
	return events


## Solo después de saldar la cuenta: volver a la vida o seguir por avaricia.
func can_retire() -> bool:
	return phase == Phase.FREE


func retire() -> Array[GameEvent]:
	if not can_retire():
		return [_illegal()]
	phase = Phase.RETIRED
	state.retired = true
	meta.debt = 0
	meta.run_in_progress = false
	_record_run()
	return [GameEvent.make(&"run_retired", {"money": state.money, "round": state.round})]


## La avaricia: en el MVP es el final malo. La cuenta ya se pagó, no queda deuda.
func condemn() -> Array[GameEvent]:
	if not can_retire():
		return [_illegal()]
	phase = Phase.CONDEMNED
	meta.debt = 0
	meta.run_in_progress = false
	_record_run()
	return [GameEvent.make(&"run_condemned", {"money": state.money, "round": state.round})]


func next_round() -> Array[GameEvent]:
	if phase != Phase.SHOP:
		return [_illegal()]
	state.round += 1
	shop.offers.clear()
	phase = Phase.BAR
	var events: Array[GameEvent] = []
	var before := state.fiado
	if state.apply_interest(economy) > 0:
		events.append(GameEvent.make(&"fiado_interest", {"before": before, "after": state.fiado}))
	_checkpoint()
	events.append(GameEvent.make(&"round_started", {"round": state.round, "entry": economy.entry(state.round)}))
	return events


## La run termina. El legado se elige después con choose_legacy().
func die() -> Array[GameEvent]:
	if state == null or phase in ENDED or phase == Phase.FREE:
		return [_illegal()]
	_legacy_snapshot = _equipped_ids()
	shop.offers.clear()
	state.die()
	meta.debt = state.debt
	meta.run_in_progress = false
	phase = Phase.DEAD
	_record_run()
	return [GameEvent.make(&"run_died", {"round": state.round, "debt": state.debt, "choices": legacy_choices()})]


## Al morir, los amuletos que tenías en ese momento (comprar después no suma).
func legacy_choices() -> Array[StringName]:
	if phase == Phase.DEAD:
		return _legacy_snapshot.duplicate()
	return _equipped_ids()


# --- Tienda (solo en la fase SHOP) ---

func buy(index: int) -> Dictionary:
	if phase != Phase.SHOP:
		return {"ok": false, "reason": &"closed", "paid": 0, "fiado": 0}
	var r := shop.buy(index, state)
	if r["ok"]:
		_checkpoint()
	return r


func sell(id: StringName) -> int:
	if phase != Phase.SHOP:
		return 0
	var value := shop.sell(id, state)
	_checkpoint()
	return value


func reroll() -> bool:
	if phase != Phase.SHOP:
		return false
	var ok := shop.reroll(state)
	_checkpoint()
	return ok


func _equipped_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for def in state.loadout.equipped():
		out.append(def.id)
	return out


func choose_legacy(id: StringName) -> bool:
	if phase != Phase.DEAD or not id in legacy_choices():
		return false
	meta.legacy = id
	meta.save_to(_meta_path)
	return true


func table() -> CheatTable:
	return systems.table if systems != null else null


## Guarda la deuda que quedaría si la run se abandona ahora (deuda + fiado).
func _checkpoint() -> void:
	meta.debt = state.debt + state.fiado
	meta.run_in_progress = true
	meta.save_to(_meta_path)


func _record_run() -> void:
	meta.runs_played += 1
	meta.best_round = maxi(meta.best_round, state.round)
	meta.save_to(_meta_path)


func _child_rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = _rng.randi()
	return r


func _illegal() -> GameEvent:
	return GameEvent.make(&"illegal_action", {"player": PLAYER, "type": -1})

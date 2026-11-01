class_name RunController
extends RefCounted
## Orquesta una run para las pantallas: bar, entrada, partido, premio, tienda,
## muerte o retiro. Emite eventos como el resto del núcleo. Ver DISENO §6 y §7.

enum Phase { BAR, MATCH, SHOP, DEAD, RETIRED }

const RIVAL_ORDER: Array[StringName] = [&"agresivo", &"mentiroso", &"tramposo"]
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
var _profiles: Dictionary
var _defs: Dictionary
var _decks: Dictionary
var _legacy_snapshot: Array[StringName] = []


func _init(p_economy: Economy, p_meta: MetaState, p_seed: int, p_meta_path: String = MetaState.DEFAULT_PATH) -> void:
	economy = p_economy
	meta = p_meta
	_meta_path = p_meta_path
	_rng = RandomNumberGenerator.new()
	_rng.seed = p_seed
	# Provisorio hasta la Tarea 5 del Plan 5b (RivalCatalog).
	_profiles = RivalProfile.load_all("res://tests/fixtures/legacy_rivals.json")
	_defs = AmuletDef.load_all()
	_decks = RunDeck.load_all()
	shop = Shop.new(economy, _defs, _child_rng())


func start_run(deck_id: StringName) -> Array[GameEvent]:
	if state != null and phase in [Phase.BAR, Phase.MATCH, Phase.SHOP]:
		return [_illegal()]
	# Una run que quedó abierta (se cerró el juego) cuenta como jugada; su fiado ya
	# quedó guardado como deuda en el último punto de control.
	if meta.run_in_progress:
		meta.runs_played += 1
	state = RunState.new()
	state.money = economy.start_money
	state.debt = meta.debt
	state.deck = _decks[deck_id]
	var legacy := meta.legacy
	if legacy != &"" and _defs.has(legacy):
		state.loadout.equip(_defs[legacy])
		state.paid_for[legacy] = 0
	# El legado se consume al empezar: guardarlo ya evita recuperarlo cerrando el juego.
	meta.legacy = &""
	phase = Phase.BAR
	_checkpoint()
	return [GameEvent.make(&"run_started", {"money": state.money, "debt": state.debt, "legacy": legacy, "deck": deck_id})]


func rival_for(round: int) -> RivalProfile:
	var id := RIVAL_ORDER[(round - 1) % RIVAL_ORDER.size()]
	return _profiles[id].scaled_for_round(round)


func enter_match() -> Array[GameEvent]:
	if state == null or phase != Phase.BAR:
		return [_illegal()]
	var entry := economy.entry(state.round)
	if not state.pay_entry(economy):
		return die()
	var rival := rival_for(state.round)
	var m := TrucoMatch.new(economy.target_points(state.round), _child_rng())
	var table := CheatTable.new(m, DealerBrain.new(rival, _child_rng()), DEALER, _child_rng())
	state.deck.apply_to(table.rules)
	systems = AmuletSystem.new(table, state.loadout, _child_rng())
	systems.start_match()
	phase = Phase.MATCH
	return [GameEvent.make(&"entry_paid", {
		"entry": entry, "rival": rival.id, "boss": economy.is_boss(state.round),
		"target": economy.target_points(state.round), "round": state.round,
	})]


func finish_match() -> Array[GameEvent]:
	if phase != Phase.MATCH or table().truco_match.winner() == -1:
		return [_illegal()]
	var t := table()
	if t.truco_match.winner() != PLAYER:
		return die()
	var prize := Prize.compute(economy.base_prize(state.round), t.truco_match.scores[DEALER],
		t.player_cheats_used, t.player_cheats_caught, t.player_called_envido,
		state.loadout, state.deck, economy)
	var paid := state.collect_prize(prize["total"], economy)
	phase = Phase.SHOP
	shop.open(state, economy.is_boss(state.round))
	_checkpoint()
	var data := {"total": prize["total"], "multipliers": prize["multipliers"], "money": state.money}
	data.merge(paid)
	return [GameEvent.make(&"prize_paid", data)]


func can_retire() -> bool:
	return phase == Phase.SHOP and state.money >= economy.goal


func retire() -> Array[GameEvent]:
	if not can_retire():
		return [_illegal()]
	phase = Phase.RETIRED
	state.retired = true
	meta.debt = 0
	meta.run_in_progress = false
	_record_run()
	return [GameEvent.make(&"run_retired", {"money": state.money, "round": state.round})]


func next_round() -> Array[GameEvent]:
	if phase != Phase.SHOP:
		return [_illegal()]
	state.round += 1
	shop.offers.clear()
	phase = Phase.BAR
	_checkpoint()
	return [GameEvent.make(&"round_started", {"round": state.round, "entry": economy.entry(state.round)})]


## La run termina. El legado se elige después con choose_legacy().
func die() -> Array[GameEvent]:
	if state == null or phase == Phase.DEAD or phase == Phase.RETIRED:
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

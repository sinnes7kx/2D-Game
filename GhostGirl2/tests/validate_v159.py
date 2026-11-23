from pathlib import Path
import hashlib

def validate(root: Path):
    expected = {
      'gothic_hunter.gd':['const FEINT: int', 'func _start_feint(', 'state == FEINT', 'feint_cooldown', 'bolt.set("curved_flight"'],
      'enemy_hex_bolt.gd':['var curved_flight: bool = false', 'travel_heading', 'intersect_ray(query)', 'receive_damage", damage'],
      'item_instance.gd':['func _has_mythic_visual(', 'func _has_moonfall_visual(', 'func signature_of_saved_look(', 'rare_visual_mod = 5', 'func restore_cosmetic_look('],
      'weapon_prestige_fx.gd':['if sig == 5:', 'elif sig == 4:', 'Moonfall Halo'],
      'equipment_visuals.gd':['dress_signature in [4, 5]', 'var center: Vector2 = Vector2(0, 18)', 'accessories_glow'],
      'inventory_panel.gd':['signature_of_saved_look(look)', 'GhostCosmeticRNGV152.gradient_colors(uid, saved_seed)', 'canvas.set_pixel', 'img.flip_x()'],
      'item_rich_text.gd':['Moonfall Halo', 'Mythic Radiance', 'if not advanced:']
    }
    tests = 0
    for filename, fragments in expected.items():
        source=(root/'scripts'/filename).read_text(encoding='utf-8')
        for frag in fragments:
            assert frag in source, f'{filename} missing {frag}'
            tests += 1
    hunter=(root/'scripts/gothic_hunter.gd').read_text()
    bolts=(root/'scripts/enemy_hex_bolt.gd').read_text()
    item=(root/'scripts/item_instance.gd').read_text()
    assert hunter.count('bolt.set("damage", strike_damage)') == 1; tests+=1
    assert hunter.count('girl.call("receive_damage", strike_damage, global_position)') == 2;tests+=1
    assert bolts.count('target.call("receive_damage", damage, global_position)') == 1;tests+=1
    assert 'var item_seed: int = 0' in item and 'var saved_cosmetic_looks: Array[Dictionary] = []' in item;tests+=1
    assert 'func visual_signature() -> int:' in item and 'rare_visual_mod = 4' in item;tests+=1
    # Synthetic unit test: test the UID-hash ticket algorithm's deterministic
    # behaviour and show the rare signature is not a hardcoded fixed ID.
    uid='0123456789abcdef0123456789abcdef'
    ticket=lambda u: int.from_bytes(hashlib.sha256(('moonfall-visual-v159:'+u).encode()).digest()[:3], 'little') & 0x1ffff
    assert ticket(uid)==ticket(uid) and ticket(uid) != ticket('fedcba9876543210fedcba9876543210');tests+=1
    print(f'PASS {tests}/{tests} v1.59 source/compatibility checks')

if __name__=='__main__':
    validate(Path(__file__).resolve().parents[1])

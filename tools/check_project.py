from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
req=['project.godot','export_presets.cfg','scripts/Game.gd','scripts/SaveSystem.gd','scenes/main.tscn','.github/workflows/android-apk.yml']
for p in req:
    assert (ROOT/p).exists(), f'Missing: {p}'
s=(ROOT/'scripts/Game.gd').read_text()
for token in ['CONTINUAR PARTIDA','NUEVA PARTIDA','STAGE 1','STAGE 2','PUNTO DE CONTROL','draw_boss','save_checkpoint','restart_checkpoint','spitter','runner']:
    assert token in s, f'Gameplay component absent: {token}'
assert 'user://ira_stage_save_v1.json' in (ROOT/'scripts/SaveSystem.gd').read_text()
hero=len(list((ROOT/'assets/sprites').glob('hero_*.png')))
enemy=len(list((ROOT/'assets/sprites').glob('enemy_*.png')))
allies=len(list((ROOT/'assets/sprites').glob('ally_*.png')))
assert hero>=30 and enemy>=60 and allies>=70, (hero,enemy,allies)
print(f'Project smoke check OK. Sprites: hero={hero}, enemies={enemy}, refugees={allies}, total={hero+enemy+allies}')

#!/usr/bin/env python3
"""
Генератор артов для карточной игры.

Прогоняет единый список из 52 сущностей через выбранный провайдер и
раскладывает PNG по assets/ с правильными именами файлов.

Провайдеры:
  pollinations  — бесплатно, без ключа (по умолчанию). Под капотом FLUX.
  gemini        — Google Gemini 2.5 Flash Image. Нужен бесплатный ключ
                  (см. инструкцию ниже в шапке или в README раздела).

Только стандартная библиотека Python (urllib) — pip ничего ставить не надо.

ПРИМЕРЫ:
  python3 design/generate_art.py                      # всё через Pollinations
  python3 design/generate_art.py --only cards         # только категория cards
  python3 design/generate_art.py --only fire_deer     # одна сущность по id
  python3 design/generate_art.py --provider gemini    # через Gemini (нужен ключ)
  python3 design/generate_art.py --seed 7 --overwrite # другой seed, перерисовать

КОНСИСТЕНТНОСТЬ СТИЛЯ:
  Единый STYLE-префикс + NEGATIVE + фиксированный --seed дают близкий стиль.
  Хочешь идеально одинаково — для Gemini можно передать референс (--ref путь),
  тогда он будет генерить «в стиле этой картинки» (см. _gen_gemini).
"""

import argparse
import base64
import json
import os
import ssl
import sys
import time
import urllib.parse
import urllib.request

# SSL-контекст. На macOS у системного Python часто не установлены корневые
# сертификаты (ошибка CERTIFICATE_VERIFY_FAILED). Пытаемся взять certifi,
# иначе используем дефолт; --insecure отключает проверку как крайний случай.
def make_ssl_context(insecure):
    if insecure:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


_ssl_ctx = ssl.create_default_context()  # переопределяется в main()


def load_dotenv():
    """Подхватывает переменные из .env в корне проекта (если есть)."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".env")
    if not os.path.exists(path):
        return
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            val = val.strip().strip('"').strip("'")
            os.environ.setdefault(key.strip(), val)

# ---------------------------------------------------------------------------
# Единый стиль (совпадает с design/ART_PROMPTS_EN.md)
# ---------------------------------------------------------------------------
STYLE = (
    "Friendly mobile-game cartoon style, soft rounded shapes, bold clean black "
    "outlines, warm saturated colors, soft cel shading, slightly chunky cute "
    "proportions, playful humorous mood, high quality game asset."
)

NEGATIVE = (
    "No text, no letters, no watermark, no signature, no logo, no UI mockup, "
    "no buttons, no card frame or border, no grid, no collage, no multiple "
    "variations in one image, only one single subject per image, "
    "no photographic realism."
)

# Тех-требования по типу ассета + ориентация (ширина, высота)
TYPES = {
    "card":     ("single character centered, full body, 3/4 view, simple flat "
                 "solid-color background, vertical portrait composition",
                 768, 1024),
    "building": ("single building isolated, 3/4 top-down view, plain flat "
                 "background, no ground scene",
                 1024, 1024),
    "env":      ("single object isolated, plain flat background, 3/4 top-down view",
                 1024, 1024),
    "duelist":  ("seated character, waist-up, facing camera, simple background",
                 1024, 1024),
    "node":     ("single round game-map badge icon, centered, flat",
                 1024, 1024),
    "icon":     ("single icon, centered, plain background, flat, clean "
                 "silhouette, app-icon style",
                 1024, 1024),
    "bg":       ("wide landscape background, no characters, calm center area "
                 "for UI overlay",
                 1216, 640),
    "tile":     ("flat top-down seamless tileable texture, fills the ENTIRE "
                 "frame edge to edge, repeating pattern, even lighting, no "
                 "vignette, no isolated object, no border, no shadow",
                 1024, 1024),
}

# ---------------------------------------------------------------------------
# Все сущности: (id, category_folder, type, описание)
# ---------------------------------------------------------------------------
ENTITIES = [
    # --- Карты огня ---
    ("fire_deer",          "cards", "card", "a cute deer made of glowing embers, small flames on its antlers, warm orange-red glow, mischievous friendly face"),
    ("fire_rooster",       "cards", "card", "a proud rooster with fiery tail feathers like flames, golden-orange plumage, confident strut, tiny sparks"),
    ("fire_pie",           "cards", "card", "a funny anthropomorphic baked pie, slightly burnt crispy edges, little flame on top, cute eyes, steam, comedic"),
    ("fire_phoenix_pearl", "cards", "card", "a glowing magical pearl wrapped in phoenix flames, radiant golden-orange fire feathers around a bright orb, majestic"),
    # --- Карты природы ---
    ("nature_zucchini",    "cards", "card", "a buff zucchini warrior with tiny muscular arms, leaf headband, determined heroic face, comedic"),
    ("nature_forester",    "cards", "card", "a jolly forester with big beard, plaid shirt, axe, rosy tipsy cheeks, goofy happy grin, holding a flask"),
    ("nature_mushroom",    "cards", "card", "a muscular mushroom flexing big arms, red speckled cap, confident bodybuilder pose, funny and cute"),
    ("nature_hedgehog",    "cards", "card", "a tiny fierce hedgehog with sharp leaf-shaped spikes, war-paint, brave little warrior stance, adorable"),
    # --- Карты воды ---
    ("water_jellyfish",    "cards", "card", "an angry jellyfish with grumpy frowning face, translucent blue glowing bell, wavy tentacles, annoyed"),
    ("water_puddle",       "cards", "card", "a heroic water-puddle character with a captain's hat and a tiny saluting arm, splashy blue water body, silly hero"),
    ("water_beaver",       "cards", "card", "a beaver plumber in overalls holding a pipe wrench, tool belt, confident handyman, water droplets, funny"),
    ("water_dumpling",     "cards", "card", "a cute dumpling encased in glittering ice, frosty blue glow, frozen breath, chubby, icy crystals"),
    # --- Козыри (эпичнее) ---
    ("trump_pumpkin_king", "cards", "card", "an epic pumpkin king on a throne, golden crown, regal cape, glowing carved face, majestic, green vines, magical aura, more detail than common cards"),
    ("trump_lava_cat",     "cards", "card", "an epic cat made of molten lava, cracked glowing rock skin, fiery mane, fierce cute eyes, orange-red magical aura, more detail than common cards"),
    ("trump_frost_granny", "cards", "card", "an epic grandmother frost sorceress, knitted shawl, glowing ice staff, frosty blue aura, kind but powerful, snowflakes, more detail than common cards"),
    ("trump_starter_drake","cards", "card", "a cute but epic baby dragon with small fiery wings, big friendly eyes, tiny flames from nostrils, heroic starter-pet, warm glow, more detail than common cards"),
    # --- Рубашка карты ---
    ("card_back",          "cards", "card", "a vertical card back design: ornate blue gradient background, golden shield crest emblem centered, decorative corners, symmetrical"),

    # --- Замок и здания (базовый уровень; уровни 2-3 см. примечание) ---
    ("castle",             "kingdom", "building", "a charming fantasy castle, light stone walls, blue cone-roof towers, wooden gate, a flag on top, warm and inviting"),
    ("fireForge",          "kingdom", "building", "a fire forge brazier building, glowing flames inside, orange-red palette, anvil and chimney with sparks"),
    ("waterWell",          "kingdom", "building", "a water well building styled like a giant 1.5L plastic water bottle structure, blue palette, dripping water, funny"),
    ("natureGrove",        "kingdom", "building", "a lush garden grove with leafy bushes and a small tree, green palette, flowers, glowing nature energy"),
    ("wall",               "kingdom", "building", "a fortified stone castle gatehouse: a wooden double-gate flanked by two short crenellated stone towers, front view, the entrance of a surrounding wall, sturdy grey-brown stone"),
    ("mine",               "kingdom", "building", "a crystal mine entrance with wooden support beams and cart rails, glowing blue-purple crystals inside"),

    # --- Окружение королевства ---
    ("bg_meadow",          "kingdom/env", "tile", "a lush green grass field surface, short cartoon grass blades all over, uniform sunny meadow, no objects"),
    ("bg_sky",             "kingdom/env", "tile", "a cheerful blue sky with evenly scattered small fluffy white clouds, soft and uniform"),
    ("road",               "kingdom/env", "env", "a dirt path road segment, brown earthy texture, top-down"),
    ("pond",               "kingdom/env", "env", "a round pond with blue water, lily pads, soft reflection, top-down 3/4"),
    ("fence",              "kingdom/env", "env", "a wooden fence segment, light brown planks, simple"),
    ("tree",               "kingdom/env", "env", "a round fluffy tree, green canopy, brown trunk"),
    ("bush",               "kingdom/env", "env", "a small green rounded bush"),
    ("flowers",            "kingdom/env", "env", "a cluster of small yellow and pink flowers"),

    # --- Дуэлянты / босс ---
    ("hero_player",        "duel", "duelist", "a friendly hero card-duelist facing forward toward the viewer, front view, symmetrical, warm skin, rounded hair, blue outfit, confident friendly smile, upper body, looking straight at camera"),
    ("villain_opponent",   "duel", "duelist", "a villain card-duelist facing forward toward the viewer, front view, symmetrical, greenish skin, spiky hair with small horns, green-brown outfit, menacing sly grin, upper body, looking straight at camera"),
    ("boss_pumpkin_lord",  "duel", "duelist", "an intimidating pumpkin lord boss, huge glowing carved pumpkin head, dark royal armor, looming menacing pose, fiery orange aura, epic boss"),

    # --- Ноды карты мира ---
    ("node_training",      "map", "node", "a training dummy wooden target icon, friendly beginner vibe"),
    ("node_battle",        "map", "node", "a crossed-swords battle icon with a small red flag"),
    ("node_boss",          "map", "node", "a fiery skull-pumpkin boss icon, glowing, dangerous"),
    ("node_locked",        "map", "node", "a golden padlock icon, greyed locked state"),

    # --- Иконки UI / валюта ---
    ("icon_crystal",       "icons", "icon", "a single glowing blue crystal gem, faceted, sparkle"),
    ("icon_castle",        "icons", "icon", "a small castle icon, clean silhouette"),
    ("icon_trump_star",    "icons", "icon", "a glowing golden star badge, rare premium feel"),
    ("icon_fire",          "icons", "icon", "a stylized orange-red flame icon, clean and bold"),
    ("icon_nature",        "icons", "icon", "a stylized green leaf icon, clean and bold"),
    ("icon_water",         "icons", "icon", "a stylized blue water droplet icon, clean and bold"),
    ("icon_victory",       "icons", "icon", "a celebration trophy burst icon, gold and confetti, joyful"),
    ("icon_defeat",        "icons", "icon", "a broken shield cracked icon, grey-red, defeat mood"),
    ("icon_craft",         "icons", "icon", "a glowing magic crafting orb crystal ball, purple-blue, mystical"),

    # --- Фоны экранов ---
    ("bg_world_map",       "backgrounds", "bg", "a fantasy world map background, winding path across grassy hills, distant castle, sunny"),
    ("bg_duel",            "backgrounds", "bg", "a duel table top, green felt surface with soft vignette, cozy tavern-game ambiance"),
    ("bg_kingdom",         "backgrounds", "bg", "a kingdom landscape: green meadow, blue sky with clouds, soft sunlight, empty buildable area, no buildings"),
    ("bg_reward_win",      "backgrounds", "bg", "a bright celebratory background, golden rays, confetti, warm glow"),
    ("bg_reward_loss",     "backgrounds", "bg", "a moody background, dim grey-blue, light cracks, somber but not scary"),

    # --- Игровая поверхность дуэли: деревянный стол из досок ---
    ("duel_table",         "backgrounds", "bg", "a rustic wooden table surface made of horizontal wooden planks, top-down view, warm brown weathered wood with visible grain, plank seams and a few nail heads, cozy tavern card-game table, soft even lighting, fills the entire frame"),
]

# Корень assets/ относительно этого файла (design/ -> ../assets)
ASSETS_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")


def build_prompt(desc, type_key):
    """Собирает полный промпт: стиль + тех-требования + сущность + негативы."""
    tech, _, _ = TYPES[type_key]
    return f"{STYLE} {tech}. Subject: {desc}. {NEGATIVE}"


# ---------------------------------------------------------------------------
# Провайдер: Pollinations (бесплатно, без ключа)
# ---------------------------------------------------------------------------
def gen_pollinations(prompt, w, h, seed):
    enc = urllib.parse.quote(prompt, safe="")
    url = (
        f"https://image.pollinations.ai/prompt/{enc}"
        f"?width={w}&height={h}&seed={seed}&model=flux&nologo=true&private=true"
    )
    req = urllib.request.Request(url, headers={"User-Agent": "card-game-art/1.0"})
    with urllib.request.urlopen(req, timeout=180, context=_ssl_ctx) as r:
        return r.read()


# ---------------------------------------------------------------------------
# Провайдер: Google Gemini 2.5 Flash Image (нужен ключ GEMINI_API_KEY)
# ---------------------------------------------------------------------------
def gen_gemini(prompt, ref_b64=None):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        sys.exit("GEMINI_API_KEY не задан. См. инструкцию в шапке файла / в чате.")
    model = "gemini-2.5-flash-image"
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={api_key}"
    )
    parts = [{"text": prompt}]
    if ref_b64:
        # Передаём референс — Gemini будет держать стиль этой картинки
        parts.insert(0, {"inline_data": {"mime_type": "image/png", "data": ref_b64}})
        parts.append({"text": "Match the art style of the reference image exactly."})
    body = {
        "contents": [{"parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"]},
    }
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"}, method="POST",
    )
    with urllib.request.urlopen(req, timeout=180, context=_ssl_ctx) as r:
        resp = json.loads(r.read())
    for part in resp["candidates"][0]["content"]["parts"]:
        if "inlineData" in part:
            return base64.b64decode(part["inlineData"]["data"])
    raise RuntimeError("Gemini не вернул картинку: " + json.dumps(resp)[:300])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", choices=["pollinations", "gemini"], default="pollinations")
    ap.add_argument("--only", help="фильтр: id сущности или папка категории (cards/kingdom/...)")
    ap.add_argument("--seed", type=int, default=42, help="seed для консистентности стиля")
    ap.add_argument("--overwrite", action="store_true", help="перерисовать уже существующие")
    ap.add_argument("--ref", help="(только gemini) путь к референс-картинке для единого стиля")
    ap.add_argument("--delay", type=float, default=1.0, help="пауза между запросами, сек")
    ap.add_argument("--insecure", action="store_true",
                    help="отключить проверку SSL (если CERTIFICATE_VERIFY_FAILED)")
    args = ap.parse_args()

    load_dotenv()
    global _ssl_ctx
    _ssl_ctx = make_ssl_context(args.insecure)

    ref_b64 = None
    if args.ref:
        with open(args.ref, "rb") as f:
            ref_b64 = base64.b64encode(f.read()).decode()

    todo = ENTITIES
    if args.only:
        todo = [e for e in ENTITIES if e[0] == args.only or e[1].split("/")[0] == args.only]
        if not todo:
            sys.exit(f"Ничего не найдено по фильтру '{args.only}'.")

    print(f"Провайдер: {args.provider} | сущностей: {len(todo)} | seed: {args.seed}")
    ok = skip = fail = 0
    for i, (eid, folder, type_key, desc) in enumerate(todo, 1):
        out_dir = os.path.normpath(os.path.join(ASSETS_ROOT, folder))
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{eid}.png")
        rel = os.path.relpath(out_path, os.path.join(ASSETS_ROOT, ".."))

        if os.path.exists(out_path) and not args.overwrite:
            print(f"[{i}/{len(todo)}] skip (есть)  {rel}")
            skip += 1
            continue

        prompt = build_prompt(desc, type_key)
        _, w, h = TYPES[type_key]
        try:
            if args.provider == "pollinations":
                data = gen_pollinations(prompt, w, h, args.seed)
            else:
                data = gen_gemini(prompt, ref_b64)
            with open(out_path, "wb") as f:
                f.write(data)
            print(f"[{i}/{len(todo)}] OK         {rel}  ({len(data)//1024} KB)")
            ok += 1
        except Exception as exc:
            print(f"[{i}/{len(todo)}] FAIL       {rel}  -> {exc}")
            if "CERTIFICATE_VERIFY" in str(exc):
                print("  ↳ Проблема SSL-сертификатов macOS. Запусти один раз:")
                print("    /Applications/Python*/Install\\ Certificates.command")
                print("    или: pip3 install certifi   (либо добавь флаг --insecure)")
            fail += 1
        time.sleep(args.delay)

    print(f"\nГотово. OK={ok} skip={skip} fail={fail}")
    print("Картинки лежат в assets/. Перезапуск повторно НЕ перерисует (нужен --overwrite).")


if __name__ == "__main__":
    main()

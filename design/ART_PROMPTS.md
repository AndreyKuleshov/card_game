# 🎨 Арт-промпты для всех сущностей игры

Документ для генерации артов через **ChatGPT (DALL·E / GPT-image)**. Стиль — **тёплый мультфильм** (cute cartoon, как Clash Royale / Hearthstone-lite), совпадает с текущим стилем замка и юморными названиями карт.

Всего сущностей под арт: **~50** (карты, козыри, рубашка, здания, замок, дуэлянты, иконки, фоны экранов).

---

## 0. Как этим пользоваться (важно!)

ChatGPT генерит **по одной картинке за раз** и сам по себе **не помнит стиль** между чатами. Чтобы 50 картинок выглядели как одна игра:

1. **Открой ОДИН чат** для всей пачки (отдельный чат на каждую категорию — карты / здания / персонажи).
2. **Первая картинка = эталон.** Сгенерь её, при необходимости попроси поправить. Это «якорь стиля».
3. Для каждой следующей пиши: **«В точно таком же стиле, как предыдущая картинка: <промпт сущности>»** (`In the exact same art style as the previous image: ...`).
4. **Всегда** добавляй технические требования (см. ниже) — иначе ChatGPT нарисует рамку/текст/фон, который сломает карточный UI.
5. После генерации сохраняй в `assets/<категория>/<entity_id>.png` (пути указаны у каждой сущности).

### 🔑 Общий стиль-префикс (вставлять в КАЖДЫЙ промпт)

```
Friendly mobile-game cartoon style, soft rounded shapes, bold clean black
outlines, warm saturated colors, soft cel shading, slightly chunky/cute
proportions, playful and humorous mood, high quality game asset.
```

### 🔧 Технические требования по типам

| Тип ассета | Добавлять в промпт |
|---|---|
| **Карты / козыри** | `single character centered, full body, 3/4 view, simple flat solid-color background (no scene), no text, no card frame, no border, vertical portrait composition` |
| **Здания** | `single building isolated, 3/4 top-down view, plain transparent or flat background, no ground scene, no text` |
| **Персонажи-дуэлянты** | `seated character, waist-up, facing camera, simple background, no text` |
| **Иконки / валюта** | `single icon, centered, plain background, flat, clean silhouette, app-icon style, no text` |
| **Фоны экранов** | `wide landscape background, no characters, no UI, no text, leave center area calm for UI overlay` |

> Совет: для карт и иконок проси `with transparent background (PNG)` — потом не надо вырезать.

---

## 1. 🔥 Карты огня (common) — `assets/cards/`

Элемент огня: тёплая палитра — оранжевый / красный / золотой, искры, лёгкое свечение.

| id | Название | Сила | Промпт (описание сущности) |
|---|---|---|---|
| `fire_deer` | Горячий Олень | 4 | `a cute cartoon deer made of glowing embers, small flames on its antlers, warm orange-red glow, mischievous friendly face` |
| `fire_rooster` | Желанный Петушок | 6 | `a proud cartoon rooster with fiery tail feathers like flames, golden-orange plumage, confident strut, tiny sparks around it` |
| `fire_pie` | Горелый Пирожок | 3 | `a funny anthropomorphic baked pie character, slightly burnt crispy edges, little flame on top, cute eyes, steam rising, comedic` |
| `fire_phoenix_pearl` | Перл Феникса | 7 | `a glowing magical pearl wrapped in phoenix flames, radiant golden-orange fire feathers swirling around a bright orb, majestic and warm` |

## 2. 🌿 Карты природы (common) — `assets/cards/`

Элемент природы: зелёная палитра — листья, дерево, мох, тёплый солнечный свет.

| id | Название | Сила | Промпт (описание сущности) |
|---|---|---|---|
| `nature_zucchini` | Боевой Кабачок | 5 | `a buff cartoon zucchini warrior with tiny muscular arms, leaf headband, determined heroic face, green vegetable hero, comedic` |
| `nature_forester` | Пьяный Лесник | 4 | `a jolly cartoon forester/woodsman with a big beard, plaid shirt, axe, rosy tipsy cheeks and a goofy happy grin, holding a flask` |
| `nature_mushroom` | Гриб-Качок | 6 | `a muscular cartoon mushroom character flexing big arms, red speckled cap, confident bodybuilder pose, funny and cute` |
| `nature_hedgehog` | Боевой Ёж | 3 | `a tiny fierce cartoon hedgehog with sharp leaf-shaped spikes, war-paint on face, brave little warrior stance, adorable` |

## 3. 💧 Карты воды (common) — `assets/cards/`

Элемент воды: голубая палитра — лёд, брызги, прохладное свечение.

| id | Название | Сила | Промпт (описание сущности) |
|---|---|---|---|
| `water_jellyfish` | Сердитая Медуза | 5 | `an angry cartoon jellyfish with grumpy frowning face, translucent blue glowing bell, wavy tentacles, comedic annoyed expression` |
| `water_puddle` | Капитан Лужа | 4 | `a heroic cartoon water puddle character with a captain's hat and tiny saluting arm, splashy blue water body, proud silly hero` |
| `water_beaver` | Бобёр-Сантехник | 6 | `a cartoon beaver plumber wearing overalls and holding a pipe wrench, tool belt, confident handyman, water droplets, funny` |
| `water_dumpling` | Ледяной Пельмень | 7 | `a cute cartoon dumpling (pelmeni) encased in glittering ice, frosty blue glow, frozen breath, chubby and adorable, icy crystals` |

## 4. 🏆 Козыри (trump) — `assets/cards/`

Козыри — **редкие, мощные**. Делай их крупнее, эпичнее, с магическим свечением и большей детализацией, чтобы визуально отличались от обычных карт.

| id | Название | Сила | Элемент | Способность | Промпт |
|---|---|---|---|---|---|
| `trump_pumpkin_king` | Король-Тыква | 9 | 🌿 | Двойной удар (×1.5) | `an epic cartoon pumpkin king sitting on a throne, golden crown, regal cape, glowing carved face, majestic and slightly menacing, green vines, magical aura` |
| `trump_lava_cat` | Лавовый Котик | 8 | 🔥 | Игнор бонуса стихии | `an epic cartoon cat made of molten lava, cracked glowing rock skin, fiery mane, fierce cute eyes, radiant orange-red magical aura` |
| `trump_frost_granny` | Морозная Бабуля | 9 | 💧 | Щит (нет урона при проигрыше) | `an epic cartoon grandmother sorceress wielding frost magic, knitted shawl, glowing ice staff, frosty blue aura, kind but powerful, snowflakes` |
| `trump_starter_drake` | Дракоша-Стартер | 8 | 🔥 | Двойной удар (×1.5) | `an epic but cute baby dragon (drake) with small fiery wings, big friendly eyes, tiny flames from nostrils, heroic starter-pet vibe, warm glow` |

## 5. 🛡️ Рубашка карты — `assets/cards/card_back.png`

```
A vertical playing-card back design: ornate blue gradient background with a
golden shield crest emblem in the center, decorative corners, fantasy mobile-
game card back, symmetrical, no text. [+ общий стиль-префикс]
```

---

## 6. 🏰 Замок и здания королевства — `assets/kingdom/`

> **Каждое здание нужно в 3 уровнях** (уровень 1 / 2 / 3 — всё больше и детальнее). Уровень 0 = пустой участок земли (можно один общий ассет `plot_empty.png`). Рисуй **в едином ракурсе 3/4 сверху**, чтобы здания стыковались на карте королевства.

| id | Название | Назначение | Промпт (база, для всех уровней) |
|---|---|---|---|
| `castle` | Замок 🏰 | Центр королевства | `a charming cartoon fantasy castle, light stone walls, blue cone-roof towers, wooden gate, a flag on top, warm and inviting, isometric 3/4 view` |
| `fireForge` | Зажигалка | +сила огненным картам | `a cartoon fire forge / brazier building, glowing flames inside, orange-red palette, anvil and chimney with sparks` |
| `waterWell` | Полторашка | +сила водяным картам | `a cartoon water well building styled like a giant 1.5L plastic water bottle structure, blue palette, dripping water, funny` |
| `natureGrove` | Травка | +сила картам природы | `a cartoon lush garden grove with leafy bushes and a small tree, green palette, flowers, glowing nature energy` |
| `wall` | Стена | +прочность замка (ХП) | `a cartoon stone fortress wall segment with crenellations / battlements, sturdy grey-brown stone, fantasy fortification` |
| `mine` | Шахта | Кристаллы 💎 за победу | `a cartoon crystal mine entrance with wooden support beams and cart rails, glowing blue-purple crystals inside, mining theme` |

**Как генерить уровни** (для каждого здания, в одном чате после базового):
- Ур.1: `... small and modest version, level 1`
- Ур.2: `... bigger and more detailed version with extra elements, level 2`
- Ур.3: `... grand maxed-out version, glowing and fully upgraded, level 3`

---

## 7. 🌳 Окружение королевства — `assets/kingdom/env/`

Тайлы/декор для карты королевства. Все в том же 3/4 ракурсе, можно с прозрачным фоном.

| id | Промпт |
|---|---|
| `bg_meadow` | `cartoon grassy meadow ground texture, soft green gradient, top-down, seamless tileable, sunny` (фон) |
| `bg_sky` | `cartoon blue sky with soft fluffy white clouds, warm cheerful, gradient` (фон) |
| `road` | `cartoon dirt path / road segment, brown earthy texture, top-down, tileable` |
| `pond` | `cartoon round pond with blue water, lily pads, soft reflection, top-down 3/4` |
| `fence` | `cartoon wooden fence segment, light brown planks, simple, isolated` |
| `tree` | `cartoon round fluffy tree, green canopy, brown trunk, isolated` |
| `bush` | `cartoon small green bush, rounded, isolated` |
| `flowers` | `cartoon cluster of small yellow and pink flowers, isolated` |

---

## 8. 👥 Персонажи-дуэлянты — `assets/duel/`

| id | Описание | Промпт |
|---|---|---|
| `hero_player` | Герой-игрок | `a friendly cartoon hero duelist, warm skin, rounded hair, blue outfit, seated at a table, kind confident smile, waist-up portrait` |
| `villain_opponent` | Злодей-противник | `a cartoon villain duelist, greenish skin, spiky hair with small horns, green-brown outfit, menacing sly grin, seated at a table, waist-up portrait` |
| `boss_pumpkin_lord` | БОСС: Тыквенный Лорд | `an intimidating cartoon pumpkin lord boss, huge glowing carved pumpkin head, dark royal armor, looming menacing pose, fiery orange aura, epic boss vibe` |

---

## 9. 🗺️ Иконки нод карты мира — `assets/map/`

| id | Назначение | Промпт |
|---|---|---|
| `node_training` | Тренировка | `a cartoon training dummy / wooden target map icon, friendly beginner vibe, round badge` |
| `node_battle` | Обычный противник 🚩 | `a cartoon crossed-swords battle map icon with a small red flag, round badge` |
| `node_boss` | Босс 🔥 | `a cartoon fiery skull-pumpkin boss map icon, glowing, dangerous, round badge` |
| `node_locked` | Заблокировано 🔒 | `a cartoon golden padlock map icon, round badge, greyed locked state` |

---

## 10. 💎 Иконки и валюта UI — `assets/icons/`

Все — простые, читаемые на маленьком размере, app-icon style, прозрачный фон.

| id | Заменяет emoji | Промпт |
|---|---|---|
| `icon_crystal` | 💎 | `a single glowing blue crystal gem icon, faceted, sparkle, app-icon style` |
| `icon_castle` | 🏰 | `a small cartoon castle icon, clean silhouette, app-icon style` |
| `icon_trump_star` | ⭐ | `a glowing golden star badge icon, rare/premium feel` |
| `icon_fire` | 🔥 | `a stylized flame icon, orange-red, clean and bold` |
| `icon_nature` | 🌿 | `a stylized green leaf icon, clean and bold` |
| `icon_water` | 💧 | `a stylized blue water droplet icon, clean and bold` |
| `icon_victory` | 🎉 | `a celebration / trophy burst icon, gold and confetti, joyful` |
| `icon_defeat` | 💥💀 | `a cartoon broken-shield / cracked icon, grey-red, defeat mood` |
| `icon_craft` | 🔮 | `a glowing magic crystal-ball / crafting orb icon, purple-blue, mystical` |

---

## 11. 🖼️ Фоны экранов — `assets/backgrounds/`

| id | Экран | Промпт |
|---|---|---|
| `bg_world_map` | Карта мира | `a cartoon fantasy world map background, winding path across grassy hills, distant castle, sunny, no UI, calm center for nodes overlay` |
| `bg_duel` | Дуэль | `a cartoon duel table top, green felt surface with soft vignette, cozy tavern-game ambiance, no cards, no UI` |
| `bg_kingdom` | Королевство | `a cartoon kingdom landscape: green meadow, blue sky with clouds, soft sunlight, empty buildable area, no buildings, no UI` |
| `bg_reward_win` | Победа | `a bright celebratory cartoon background, golden rays, confetti, warm glow, no characters, no text` |
| `bg_reward_loss` | Поражение | `a moody cartoon background, dim grey-blue, light cracks, somber but not scary, no characters, no text` |

---

## ✅ Чеклист генерации (по категориям, в порядке приоритета)

- [ ] **Карты (12) + козыри (4) + рубашка (1)** — самое важное, видно постоянно.
- [ ] **Замок + 5 зданий × 3 уровня (~16)** — экран королевства.
- [ ] **Дуэлянты (2) + босс (1)** — экран дуэли.
- [ ] **Иконки UI (9) + валюта** — заменяют эмодзи.
- [ ] **Ноды карты (4) + фоны экранов (5)** — атмосфера.
- [ ] **Окружение королевства (8)** — декор, можно в последнюю очередь.

> Когда арты будут готовы — следующий шаг: подключить PNG вместо процедурной отрисовки в `lib/ui/art.dart` и эмодзи в `lib/ui/theme.dart` / `widgets.dart`. Скажи, и я помогу с интеграцией.

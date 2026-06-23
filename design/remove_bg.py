#!/usr/bin/env python3
"""
Удаление однотонного фона у ассетов (иконки, здания, ноды карты).

Картинки от FLUX/Pollinations имеют плотный одноцветный фон (белый/кремовый),
а не альфа-канал. Здесь — лёгкий chroma-key: заливка от краёв изображения по
порогу цвета через связные компоненты (scipy). Это не трогает похожие цвета
ВНУТРИ объекта (например, белые блики в кристалле), потому что вырезается
только фон, связный с краями.

Зависимости: Pillow, numpy, scipy (уже установлены).

ПРИМЕРЫ:
  python3 design/remove_bg.py                       # дефолтные категории (icons, kingdom, map)
  python3 design/remove_bg.py --only icons          # только иконки
  python3 design/remove_bg.py --only castle         # один файл по id
  python3 design/remove_bg.py --tolerance 40        # агрессивнее (если фон не весь ушёл)
  python3 design/remove_bg.py --keep                # не перезаписывать, писать *_nobg.png

По умолчанию КАРТЫ и ФОНЫ ЭКРАНОВ не трогаются (им фон нужен).
Перезаписывает файлы на месте (originals можно перегенерить generate_art.py).
"""

import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ASSETS_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

# Категории, у которых фон вырезаем по умолчанию (overlay-ассеты).
# cards/ и backgrounds/ намеренно НЕ включены — им фон нужен.
DEFAULT_CATS = ["icons", "kingdom", "map", "duel"]


def remove_bg(path, tolerance, expand, keep):
    img = Image.open(path).convert("RGBA")
    arr = np.asarray(img).astype(np.int16)
    rgb = arr[:, :, :3]
    h, w = rgb.shape[:2]

    # Опорный цвет фона — медиана по четырём углам (патч 12x12).
    p = 12
    corners = np.concatenate([
        rgb[:p, :p].reshape(-1, 3),
        rgb[:p, -p:].reshape(-1, 3),
        rgb[-p:, :p].reshape(-1, 3),
        rgb[-p:, -p:].reshape(-1, 3),
    ])
    bg = np.median(corners, axis=0)

    # Кандидаты в фон: близки к опорному цвету.
    dist = np.sqrt(((rgb - bg) ** 2).sum(axis=2))
    candidate = dist <= tolerance

    # Связные компоненты кандидатов; оставляем только те, что касаются краёв.
    labels, n = ndimage.label(candidate)
    border = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
    border.discard(0)
    bg_mask = np.isin(labels, list(border))

    # Расширяем маску фона внутрь на expand px — убирает светлый ореол по контуру.
    if expand > 0:
        bg_mask = ndimage.binary_dilation(bg_mask, iterations=expand)

    out = arr.copy().astype(np.uint8)
    out[:, :, 3] = np.where(bg_mask, 0, 255).astype(np.uint8)

    pct = 100.0 * bg_mask.sum() / (h * w)
    out_path = path if not keep else path.replace(".png", "_nobg.png")
    Image.fromarray(out, "RGBA").save(out_path)
    return out_path, pct


def collect(only):
    items = []
    for root, _, files in os.walk(os.path.normpath(ASSETS_ROOT)):
        for fn in files:
            if not fn.endswith(".png") or fn.endswith("_nobg.png"):
                continue
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, os.path.normpath(ASSETS_ROOT))
            top = rel.split(os.sep)[0]
            eid = os.path.splitext(fn)[0]
            if only:
                if eid == only or top == only or rel.startswith(only):
                    items.append(full)
            elif top in DEFAULT_CATS:
                items.append(full)
    return sorted(items)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="id ассета или категория (icons/kingdom/map/duel)")
    ap.add_argument("--tolerance", type=float, default=30.0,
                    help="порог близости к цвету фона (больше = агрессивнее)")
    ap.add_argument("--expand", type=int, default=1,
                    help="на сколько px расширить маску фона внутрь (убирает ореол)")
    ap.add_argument("--keep", action="store_true",
                    help="не перезаписывать, сохранять рядом как *_nobg.png")
    args = ap.parse_args()

    items = collect(args.only)
    if not items:
        raise SystemExit(f"Нечего обрабатывать (фильтр '{args.only}').")

    print(f"Удаление фона: {len(items)} файлов, tolerance={args.tolerance}, expand={args.expand}")
    for i, path in enumerate(items, 1):
        rel = os.path.relpath(path, os.path.join(ASSETS_ROOT, ".."))
        try:
            _, pct = remove_bg(path, args.tolerance, args.expand, args.keep)
            print(f"[{i}/{len(items)}] OK   {rel}  (вырезано {pct:.0f}% фона)")
        except Exception as exc:
            print(f"[{i}/{len(items)}] FAIL {rel}  -> {exc}")
    print("Готово.")


if __name__ == "__main__":
    main()

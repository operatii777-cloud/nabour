import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math

SIZE = 1024
cx, cy = SIZE // 2, SIZE // 2

def new_layer():
    return Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

def compose(*layers):
    base = new_layer()
    for l in layers:
        base = Image.alpha_composite(base, l)
    return base

def grad_ellipse(draw, bbox, c_center, c_edge, steps=28):
    x1, y1, x2, y2 = bbox
    W = x2 - x1
    H = y2 - y1
    for i in range(steps, -1, -1):
        t = i / steps
        c = tuple(int(c_center[k] * (1-t) + c_edge[k] * t) for k in range(3))
        px = W * t / (steps * 2)
        py = H * t / (steps * 2)
        lx1, ly1 = x1 + px, y1 + py
        lx2, ly2 = x2 - px, y2 - py
        if lx2 > lx1 and ly2 > ly1:
            draw.ellipse([lx1, ly1, lx2, ly2], fill=(*c, 255))

def grad_circle(draw, cx, cy, r, c_center, c_edge, steps=20):
    for i in range(steps, -1, -1):
        t = i / steps
        c = tuple(int(c_center[k] * (1-t) + c_edge[k] * t) for k in range(3))
        ri = max(1, int(r * (1 - t * 0.5)))
        ox = int(-r * 0.15 * (1-t))
        oy = int(-r * 0.15 * (1-t))
        draw.ellipse([cx-ri+ox, cy-ri+oy, cx+ri+ox, cy+ri+oy], fill=(*c, 255))

def tube(draw, p0, p1, r0, r1, color, steps=12):
    for i in range(steps+1):
        t = i / steps
        x = int(p0[0] + (p1[0]-p0[0]) * t)
        y = int(p0[1] + (p1[1]-p0[1]) * t)
        r = max(2, int(r0 + (r1-r0)*t))
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(*color, 240))

# ── Palette ─────────────────────────────────────────────────────────────────
SK_D   = (35, 48, 38)
SK_B   = (68, 88, 62)
SK_M   = (100, 122, 88)
SK_L   = (142, 162, 125)
SK_HL  = (175, 195, 155)
AR_D   = (38, 32, 25)
AR_B   = (72, 62, 48)
AR_L   = (138, 118, 88)
LOCK_D = (28, 42, 30)
LOCK_B = (52, 72, 48)
LOCK_R = (70, 55, 38)   # ring color
EYE_A  = (205, 158, 12)
EYE_S  = (15, 8, 4)
EYE_HL = (255, 235, 180)
MAN_B  = (82, 72, 52)
MAN_T  = (205, 190, 150)
TOOTH  = (230, 218, 180)
BIO    = (62, 198, 130)
CANNON = (55, 48, 36)
FLAME  = (42, 200, 130)

img = new_layer()
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# DREADLOCKS — drawn as solid tapering tubes with ring bands
# ═══════════════════════════════════════════════════════════════════════════
lock_data = [
    # (start_x_offset, length, curve_x, curve_y)  — relative to head center
    (-118, 310, -55,  30),
    ( -85, 330, -42,  40),
    ( -50, 340, -18,  45),
    ( -12, 345,   5,  50),
    (  25, 342,  28,  48),
    (  62, 332,  50,  42),
    (  95, 315,  65,  32),
]
head_top = cy - 415  # top of head

for (dx, length, cdx, cdy) in lock_data:
    ox = cx + dx
    oy = head_top + 20
    ex = cx + dx + cdx
    ey = oy + length
    r_base = 13
    r_tip  = 5
    STEPS  = 18
    # draw tube
    for s in range(STEPS+1):
        t = s / STEPS
        # cubic bezier-ish via simple quadratic
        bx = int((1-t)**2 * ox + 2*(1-t)*t*(ox+cdx//2) + t**2 * ex)
        by = int((1-t)**2 * oy + 2*(1-t)*t*(oy+length//2) + t**2 * ey)
        r  = max(r_tip, int(r_base * (1-t*0.55)))
        shade = tuple(int(LOCK_D[k] + (LOCK_B[k]-LOCK_D[k])*(0.2+0.6*t)) for k in range(3))
        draw.ellipse([bx-r, by-r, bx+r, by+r], fill=(*shade, 245))
        # highlight stripe
        draw.ellipse([bx-r+2, by-r+1, bx-r//3, by-r//3], fill=(SK_M[0], SK_M[1], SK_M[2], 80))
    # ring bands every ~45px along length
    for s in range(2, STEPS, 4):
        t = s / STEPS
        bx = int((1-t)**2 * ox + 2*(1-t)*t*(ox+cdx//2) + t**2 * ex)
        by = int((1-t)**2 * oy + 2*(1-t)*t*(oy+length//2) + t**2 * ey)
        r  = max(r_tip, int(r_base * (1-t*0.55))) + 2
        draw.ellipse([bx-r, by-r, bx+r, by+r], fill=(*LOCK_R, 200))

# ═══════════════════════════════════════════════════════════════════════════
# TAIL / LOWER BODY
# ═══════════════════════════════════════════════════════════════════════════
tail_pts = [
    (cx-38, cy+268),(cx+38, cy+268),
    (cx+42, cy+370),(cx+62, cy+455),(cx+40, cy+485),
    (cx+12, cy+430),(cx-5,  cy+375),(cx-38, cy+268),
]
draw.polygon(tail_pts, fill=SK_D)
# spines on tail
for (tx, ty) in [(cx+52, cy+345),(cx+58, cy+398),(cx+48, cy+445)]:
    draw.polygon([(tx,ty),(tx+8,ty-22),(tx+22,ty)], fill=AR_B)
    draw.line([(tx+8,ty-22),(tx+15,ty-8)], fill=(*AR_L, 160), width=2)

# ═══════════════════════════════════════════════════════════════════════════
# TORSO — main body sphere with gradient
# ═══════════════════════════════════════════════════════════════════════════
grad_ellipse(draw, [cx-185, cy-38, cx+185, cy+272], SK_L, SK_D)

# mesh netting
for yy in range(cy-20, cy+272, 20):
    for xx in range(cx-185, cx+185, 20):
        ex_r = (xx - cx) / 185
        ey_r = (yy - (cy+117)) / 155
        if ex_r**2 + ey_r**2 < 0.92:
            draw.line([(xx, yy),(xx+20, yy+20)], fill=(*AR_D, 45), width=1)
            draw.line([(xx+20, yy),(xx, yy+20)], fill=(*AR_D, 30), width=1)

# chest breastplate
draw.polygon([(cx-125,cy+15),(cx+125,cy+15),(cx+98,cy+142),(cx-98,cy+142)], fill=(*AR_B, 235))
draw.polygon([(cx-98,cy+150),(cx+98,cy+150),(cx+72,cy+262),(cx-72,cy+262)], fill=(*AR_D, 235))
# plate edges / highlights
draw.line([(cx-123,cy+17),(cx+123,cy+17)], fill=(*AR_L, 185), width=3)
draw.line([(cx-96, cy+152),(cx+96, cy+152)], fill=(*AR_L, 130), width=2)
# bio-accent horizontal lines
for yo in [cy+72, cy+102, cy+132]:
    w = int(95 - (yo - cy - 72) * 0.3)
    draw.line([(cx-w, yo),(cx+w, yo)], fill=(*BIO, 100), width=2)
# central gem
draw.ellipse([cx-14, cy+52, cx+14, cy+80], fill=(*BIO, 240))
draw.ellipse([cx-8,  cy+57, cx+8,  cy+75], fill=(12, 28, 20, 255))
draw.ellipse([cx-5,  cy+59, cx-1,  cy+64], fill=(180, 255, 210, 200))

# ═══════════════════════════════════════════════════════════════════════════
# SHOULDERS — connect to torso
# ═══════════════════════════════════════════════════════════════════════════
for sx in [-1, 1]:
    ox = cx + sx * 162
    grad_ellipse(draw, [ox-58, cy-58, ox+58, cy+52], AR_L, AR_D)
    draw.ellipse([ox-44, cy-58, ox+4*sx, cy-18], fill=(*AR_L, 175))
    draw.ellipse([ox-10, cy+18, ox+10, cy+38], fill=(*BIO, 215))

# ═══════════════════════════════════════════════════════════════════════════
# ARMS — attached to shoulders, tapering to forearms
# ═══════════════════════════════════════════════════════════════════════════
for sx in [-1, 1]:
    shoulder_cx = cx + sx * 162
    shoulder_cy = cy - 3
    # upper arm
    elbow_x = cx + sx * 248
    elbow_y = cy + 145
    tube(draw, (shoulder_cx, shoulder_cy+50), (elbow_x, elbow_y), 28, 20, SK_B)
    # elbow joint
    grad_circle(draw, elbow_x, elbow_y, 22, SK_M, SK_D)
    # forearm armor band
    fa_x = elbow_x + sx * 15
    fa_y = elbow_y + 30
    draw.ellipse([fa_x-26, fa_y-12, fa_x+26, fa_y+12], fill=(*AR_B, 230))
    # lower arm
    hand_x = cx + sx * 265
    hand_y = cy + 240
    tube(draw, (elbow_x, elbow_y+20), (hand_x, hand_y-20), 18, 13, SK_D)
    # wrist armor
    draw.ellipse([hand_x-20, hand_y-30, hand_x+20, hand_y+10], fill=(*AR_D, 220))
    # 3 claws
    for i, adeg in enumerate([-22, 0, 22]):
        rad = math.radians(adeg)
        tx = int(hand_x + sx * 48 * math.cos(rad))
        ty = int(hand_y + 18 + 22 * abs(math.sin(rad)))
        draw.line([(hand_x, hand_y), (tx, ty)], fill=(*MAN_T, 235), width=7)
        # claw tip
        draw.ellipse([tx-5, ty-5, tx+5, ty+5], fill=(*TOOTH, 255))

# ═══════════════════════════════════════════════════════════════════════════
# NECK — connects head to torso
# ═══════════════════════════════════════════════════════════════════════════
grad_ellipse(draw, [cx-68, cy-162, cx+68, cy+18], SK_M, SK_D, steps=15)
# neck armor rings
for ny in [cy-120, cy-80, cy-40]:
    draw.ellipse([cx-58, ny-8, cx+58, ny+8], fill=(*AR_B, 200))
    draw.line([(cx-55, ny),(cx+55, ny)], fill=(*AR_L, 120), width=1)

# ═══════════════════════════════════════════════════════════════════════════
# HEAD — elongated Predator skull
# ═══════════════════════════════════════════════════════════════════════════
grad_ellipse(draw, [cx-138, cy-435, cx+138, cy-98], SK_HL, SK_D, steps=38)

# cranial ridges
for dx in [-42, -14, 14, 42]:
    # ridge body
    draw.polygon([
        (cx+dx-11, cy-432),(cx+dx+11, cy-432),
        (cx+dx+7,  cy-315),(cx+dx-7,  cy-315),
    ], fill=(*SK_M, 210))
    draw.line([(cx+dx, cy-428),(cx+dx, cy-320)], fill=(*SK_HL, 150), width=2)

# brow ridge
draw.ellipse([cx-128, cy-295, cx+128, cy-250], fill=(*SK_D, 255))
draw.ellipse([cx-118, cy-300, cx+118, cy-258], fill=(*SK_M, 210))

# ═══════════════════════════════════════════════════════════════════════════
# EYES — amber, vertical slit pupils, realistic reflections
# ═══════════════════════════════════════════════════════════════════════════
for ex in [cx-68, cx+68]:
    ey_pos = cy - 280
    # socket shadow
    draw.ellipse([ex-46, ey_pos-33, ex+46, ey_pos+33], fill=(10, 8, 6, 255))
    # iris gradient
    for r in range(38, 0, -2):
        t = r / 38
        shade = tuple(int(EYE_A[k] * (0.45 + 0.55*(1-t))) for k in range(3))
        draw.ellipse([ex-r, int(ey_pos-r*0.78), ex+r, int(ey_pos+r*0.78)], fill=(*shade, 255))
    # vertical slit pupil
    draw.ellipse([ex-11, ey_pos-28, ex+11, ey_pos+28], fill=(*EYE_S, 255))
    # highlight top-left
    draw.ellipse([ex-24, ey_pos-22, ex-8, ey_pos-10], fill=(*EYE_HL, 210))
    # small secondary glint
    draw.ellipse([ex+12, ey_pos+10, ex+20, ey_pos+18], fill=(200, 175, 80, 130))
    # amber rim glow (soft)
    glow_l = new_layer()
    gd = ImageDraw.Draw(glow_l)
    for gr in range(55, 15, -5):
        ga = int(55 * (1 - gr/55)**1.2)
        gd.ellipse([ex-gr, int(ey_pos-gr*0.78), ex+gr, int(ey_pos+gr*0.78)], fill=(*EYE_A, ga))
    glow_l = glow_l.filter(ImageFilter.GaussianBlur(radius=7))
    img = Image.alpha_composite(img, glow_l)
    draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# LOWER FACE / MOUTH AREA
# ═══════════════════════════════════════════════════════════════════════════
draw.ellipse([cx-88, cy-222, cx+88, cy-148], fill=(*SK_D, 255))
# nostrils
for nx in [cx-28, cx+10]:
    draw.ellipse([nx, cy-206, nx+16, cy-182], fill=(18, 12, 10, 235))

# ═══════════════════════════════════════════════════════════════════════════
# MANDIBLES — 4 spreading tubes (Predator signature)
# ═══════════════════════════════════════════════════════════════════════════
mby = cy - 198
mandibles = [
    ((cx-18, mby), (cx-88,  mby+100), 11, 6),  # outer left
    ((cx-6,  mby), (cx-38,  mby+90),  8,  5),  # inner left
    ((cx+6,  mby), (cx+38,  mby+90),  8,  5),  # inner right
    ((cx+18, mby), (cx+88,  mby+100), 11, 6),  # outer right
]
for (bx,by),(tx,ty), r0, r1 in mandibles:
    MSTEPS = 14
    for s in range(MSTEPS+1):
        frac = s / MSTEPS
        x = int(bx + (tx-bx)*frac)
        y = int(by + (ty-by)*frac)
        r = max(r1, int(r0*(1-frac*0.45)))
        c = tuple(int(MAN_B[k] + (MAN_T[k]-MAN_B[k])*frac) for k in range(3))
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(*c, 245))
        # highlight stripe
        draw.ellipse([x-r+2, y-r, x-r//2, y-r//2+2], fill=(SK_L[0],SK_L[1],SK_L[2], 70))
    # tip highlight
    draw.ellipse([tx-5, ty-5, tx+5, ty+5], fill=(*TOOTH, 255))

# ═══════════════════════════════════════════════════════════════════════════
# SHOULDER CANNON (right shoulder, iconic Predator accessory)
# ═══════════════════════════════════════════════════════════════════════════
sc_ox = cx + 162
sc_oy = cy - 58
# mount / housing attached to shoulder
draw.ellipse([sc_ox+18, sc_oy-28, sc_ox+78, sc_oy+28], fill=(*AR_D, 255))
draw.ellipse([sc_ox+22, sc_oy-22, sc_ox+68, sc_oy+20], fill=(*AR_B, 235))
# 3 barrels
for i, (dy, dr) in enumerate([(-16, 9), (0, 11), (16, 9)]):
    bx1 = sc_ox + 72
    bx2 = sc_ox + 180
    by1 = sc_oy + dy
    # barrel tube
    tube(draw, (bx1, by1), (bx2, by1), dr, dr-2, CANNON)
    # barrel highlight
    draw.line([(bx1+2, by1-dr+3),(bx2-8, by1-dr+3)], fill=(*AR_L, 100), width=2)
    # muzzle glow
    mg = 5 if i == 1 else 4
    draw.ellipse([bx2-mg, by1-mg, bx2+mg, by1+mg], fill=(*FLAME, 255))
    draw.ellipse([bx2-mg+2, by1-mg+2, bx2+mg-2, by1+mg-2], fill=(200, 255, 230, 220))

# ═══════════════════════════════════════════════════════════════════════════
# FINAL POLISH
# ═══════════════════════════════════════════════════════════════════════════
final = img

# Contrast + color boost
final_rgb = final.convert('RGB')
final_rgb = ImageEnhance.Contrast(final_rgb).enhance(1.18)
final_rgb = ImageEnhance.Color(final_rgb).enhance(1.12)
r_ch, g_ch, b_ch = final_rgb.split()
a_ch = final.split()[3]
final = Image.merge('RGBA', (r_ch, g_ch, b_ch, a_ch))

out = 'e:/variante app friends/03.07.2025 MAP BOX/nabour_app/assets/images/avatars/cyber_predator.png'
final.save(out)
print(f"Done: {out}")

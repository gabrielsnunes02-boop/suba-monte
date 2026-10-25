"""Gera as texturas pintadas do terreno (grama, terra e rocha), no estilo dos jogos de PSP:
cor com volume já pintado (sombras nas frestas, luz nas bordas), 512 px e sem emendas.

Uso: python3 tools/gerar_texturas.py  (grava em assets/mundo/terreno/)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

N = 512
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "mundo", "terreno")
rng = np.random.default_rng(7)


def fractal(beta=2.0, lo=1.0, size=N):
    """Ruído fractal periódico (sem emendas) por síntese espectral, normalizado em 0..1."""
    f = np.fft.fftfreq(size) * size
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt(fx * fx + fy * fy)
    r[0, 0] = 1.0
    amp = 1.0 / np.maximum(r, lo) ** (beta / 2.0)
    amp[0, 0] = 0.0
    spec = amp * np.exp(2j * np.pi * rng.random((size, size)))
    n = np.real(np.fft.ifft2(spec))
    return (n - n.min()) / (n.max() - n.min())


def ramp(t, stops):
    """Mapeia 0..1 numa rampa de cores [(pos, (r,g,b)), ...]."""
    t = np.clip(t, 0.0, 1.0)
    out = np.zeros(t.shape + (3,))
    ps = [s[0] for s in stops]
    for c in range(3):
        out[..., c] = np.interp(t, ps, [s[1][c] for s in stops])
    return out


def shade(height, strength=2.5):
    """Luz pintada vinda do alto à esquerda a partir de um mapa de altura (periódico)."""
    dx = np.roll(height, -1, 1) - np.roll(height, 1, 1)
    dy = np.roll(height, -1, 0) - np.roll(height, 1, 0)
    return np.clip(1.0 + (-dx - dy) * strength * N / 64.0, 0.55, 1.45)


def wrap_stamp(canvas, x, y, stamp, alpha):
    """Cola um carimbo com alfa em (x, y), dando a volta nas bordas."""
    h, w = alpha.shape
    ys = (np.arange(h) + y) % N
    xs = (np.arange(w) + x) % N
    sub = canvas[np.ix_(ys, xs)]
    a = alpha[..., None]
    canvas[np.ix_(ys, xs)] = sub * (1 - a) + stamp * a


def save(name, rgb, alpha=None):
    os.makedirs(OUT, exist_ok=True)
    img = np.clip(rgb * 255.0, 0, 255).astype(np.uint8)
    if alpha is not None:
        a = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)[..., None]
        im = Image.fromarray(np.concatenate([img, a], 2), "RGBA")
    else:
        im = Image.fromarray(img, "RGB")
    im.save(os.path.join(OUT, name), optimize=True)
    print("ok", name)


def grama():
    big = fractal(2.8, 1.5)
    mid = fractal(2.2, 5.0)
    fine = fractal(1.6, 24.0)
    t = big * 0.6 + mid * 0.32 + fine * 0.08
    col = ramp(t, [
        (0.0, (0.14, 0.19, 0.08)), (0.3, (0.23, 0.30, 0.11)), (0.55, (0.33, 0.39, 0.15)),
        (0.8, (0.45, 0.47, 0.22)), (1.0, (0.56, 0.54, 0.30)),
    ])
    # Áreas de terra seca no meio da grama.
    dry = np.clip((fractal(2.6, 3.0) - 0.62) * 3.5, 0, 1)[..., None] * 0.55
    col = col * (1 - dry) + np.array((0.40, 0.34, 0.20)) * dry
    # Folhas pintadas: traços curtos inclinados, claros e escuros.
    for i in range(2600):
        x, y = rng.integers(0, N, 2)
        length = rng.integers(8, 18)
        ang = rng.normal(-1.25, 0.35)
        light = rng.random() < 0.55
        c = np.array((0.55, 0.62, 0.28) if light else (0.10, 0.16, 0.05)) * rng.uniform(0.8, 1.15)
        for k in range(length):
            px = int(x + np.cos(ang) * k) % N
            py = int(y + np.sin(ang) * k) % N
            a = 0.45 * (1 - k / length)
            col[py, px] = col[py, px] * (1 - a) + c * a
    # Manchas de musgo escuro e pontos de luz (sol entre as folhas).
    moss = np.clip((fractal(2.4, 3.0) - 0.55) * 4.0, 0, 1)[..., None]
    col = col * (1 - moss * 0.45) + np.array((0.10, 0.18, 0.06)) * moss * 0.45
    col *= shade(big * 0.4 + mid * 0.6, 1.2)[..., None]
    img = Image.fromarray(np.clip(col * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.SMOOTH)
    # Alfa = "altura" usada para recortar a transição grama/terra de forma irregular.
    save("grama.png", np.asarray(img) / 255.0, mid * 0.6 + fine * 0.4)


def terra():
    big = fractal(2.4, 2.0)
    mid = fractal(2.2, 6.0)
    fine = fractal(1.6, 30.0)
    t = big * 0.55 + mid * 0.37 + fine * 0.08
    col = ramp(t, [
        (0.0, (0.24, 0.19, 0.13)), (0.4, (0.38, 0.31, 0.21)), (0.7, (0.50, 0.43, 0.31)),
        (1.0, (0.62, 0.56, 0.43)),
    ])
    # Rachaduras: vales de um ruído "ridged".
    ridge = 1.0 - np.abs(fractal(2.0, 4.0) * 2 - 1)
    crack = np.clip((ridge - 0.93) * 14.0, 0, 1)[..., None]
    col = col * (1 - crack * 0.5)
    col *= shade(big * 0.3 + mid * 0.7, 1.4)[..., None]
    height = mid * 0.6 + fine * 0.4
    # Pedrinhas com luz em cima e sombra embaixo.
    for i in range(260):
        r = rng.uniform(2.0, 5.0) if rng.random() < 0.85 else rng.uniform(5.0, 10.0)
        s = int(r * 2 + 4)
        yy, xx = np.mgrid[0:s, 0:s] - s / 2.0
        e = (xx / r) ** 2 + (yy / (r * rng.uniform(0.6, 0.9))) ** 2
        alpha = np.clip((1.0 - e) * 3.0, 0, 1)
        base = np.array((0.50, 0.46, 0.39)) * rng.uniform(0.6, 1.05)
        lit = np.clip(1.15 - (xx + yy) / (r * 2.2), 0.55, 1.4)
        stamp = base * lit[..., None]
        x, y = rng.integers(0, N, 2)
        # Sombra deslocada antes da pedra.
        sh = np.clip((1.0 - ((xx - 1.5) / r) ** 2 - ((yy - 2) / r) ** 2) * 2.0, 0, 1) * 0.45
        wrap_stamp(col, x, y, col[np.ix_((np.arange(s) + y) % N, (np.arange(s) + x) % N)] * 0.5, sh)
        wrap_stamp(col, x, y, stamp, alpha)
        ys = (np.arange(s) + y) % N
        xs = (np.arange(s) + x) % N
        height[np.ix_(ys, xs)] = np.maximum(height[np.ix_(ys, xs)], alpha)
    save("terra.png", col, height)


def rocha():
    big = fractal(2.8, 1.5)
    mid = fractal(2.3, 4.0)
    fine = fractal(1.6, 24.0)
    yy = np.mgrid[0:N, 0:N][0] / N
    # Camadas horizontais (estratos) bem entortadas pelo ruído; 3 por volta para emendar.
    strata = np.sin((yy * 3 + big * 1.6 + mid * 0.5) * 2 * np.pi) * 0.5 + 0.5
    ridge = 1.0 - np.abs(mid * 2 - 1)
    h = big * 0.45 + strata * 0.18 + ridge * 0.34 + fine * 0.03
    col = ramp(h, [
        (0.0, (0.20, 0.19, 0.16)), (0.35, (0.36, 0.35, 0.29)), (0.65, (0.50, 0.49, 0.41)),
        (1.0, (0.66, 0.65, 0.56)),
    ])
    crev = np.clip((ridge - 0.92) * 9.0, 0, 1) + np.clip((0.08 - strata) * 6.0, 0, 1) * 0.4
    col *= (1 - np.clip(crev, 0, 1) * 0.55)[..., None]
    col *= shade(big * 0.5 + ridge * 0.5, 1.6)[..., None]
    # Sujeira/musgo nas partes baixas.
    moss = np.clip((fractal(2.2, 4.0) - 0.6) * 3.0, 0, 1)[..., None] * 0.5
    col = col * (1 - moss) + np.array((0.25, 0.30, 0.14)) * moss
    img = Image.fromarray(np.clip(col * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    save("rocha.png", np.asarray(img) / 255.0)


if __name__ == "__main__":
    grama()
    terra()
    rocha()
    sys.exit(0)

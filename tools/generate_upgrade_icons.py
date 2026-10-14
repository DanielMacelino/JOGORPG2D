"""Permanent attribute medallions, sharing the cabinet's metalwork."""
from pathlib import Path
from generate_relic_icons import ART, build

SYMBOLS = {
    'vitality': ('#ff6e86', ART['blood_pact'][1]),
    'might': ('#f09e69', '<path d="M84 67L103 75L162 161L149 171L87 88ZM172 67L153 75L94 161L107 171L169 88Z" fill="url(#metal)" stroke="#ffe2ad" stroke-width="2"/><path d="M132 160L164 139M92 139L124 160M157 166L173 188M99 166L83 188" stroke="url(#gem)" stroke-width="9"/>'),
    'fortune': ('#f6d278', '<g fill="url(#metal)" stroke="#fff0b4" stroke-width="3"><ellipse cx="102" cy="148" rx="37" ry="29"/><ellipse cx="158" cy="146" rx="34" ry="29"/><circle cx="128" cy="109" r="37"/></g><path d="M128 86L138 109L128 133L118 109Z" fill="url(#gem)" stroke="#6a5935" stroke-width="3"/><path d="M93 135V157M151 137V158" stroke="#705b2b" stroke-width="5"/>'),
    'resilience': ('#87ddb0', ART['mirror_shield'][1]),
    'swiftness': ('#77dfd9', '<path d="M109 75L156 81L145 135L166 150L179 153L182 175L155 184L88 170L87 145L104 133Z" fill="url(#metal)" stroke="#d1e9d2" stroke-width="3"/><path d="M106 94L152 101M104 113L149 120M94 149L145 161M89 170L155 184L182 175" fill="none" stroke="url(#gem)" stroke-width="6"/><path d="M65 99H95M58 116H88M65 133H84" stroke="#96e7d9" stroke-width="4"/>'),
    'crit_mastery': ('#c897ff', ART['cursed_eye'][1]),
    'xp_boost': ('#79cfff', ART['ancient_tome'][1]),
    'attack_speed': ('#ffc05f', '<path d="M140 58L85 133H119L105 196L175 108H138L154 58Z" fill="url(#gem)" stroke="#fff0c4" stroke-width="3"/><path d="M140 58L119 133L105 196L145 121H115Z" fill="#fff4c7" opacity=".6"/><path d="M74 98H98M166 154H190M65 115H81" stroke="#e9c984" stroke-width="3"/>'),
}

if __name__ == '__main__':
    target = Path(__file__).resolve().parents[1] / 'assets/art/upgrades'
    target.mkdir(parents=True, exist_ok=True)
    for name, (color, symbol) in SYMBOLS.items():
        (target / f'{name}.svg').write_text(build(color, symbol), encoding='utf-8')
    print(f'Generated {len(SYMBOLS)} attribute illustrations')

"""Build the game's scalable relic illustrations. No fonts or emoji required."""
from pathlib import Path
import math

TARGET = Path(__file__).resolve().parents[1] / "assets/art/relics"

ART = {
    "blood_pact": ('#24bfff', '<path d="M128 181L76 126Q61 94 88 86Q111 77 128 103Q146 77 169 86Q196 95 180 126Z" fill="url(#gem)" stroke="#c8f5ff" stroke-width="3"/><path d="M88 86L104 120L76 126M104 120L128 103L151 121L169 86M104 120L128 181L151 121L180 126M104 120L151 121" fill="none" stroke="#c8f5ff" stroke-opacity=".75" stroke-width="2"/><path d="M128 103L104 120L128 181Z" fill="#f4ffff" opacity=".22"/>'),
    "golden_compass": ('#e8b946', '<circle cx="128" cy="128" r="39" fill="url(#metal)" stroke="#ffe3a2" stroke-width="3"/><path d="M128 61L141 115L181 128L141 141L128 195L115 141L75 128L115 115Z" fill="url(#gem)" stroke="#ffedb6" stroke-width="2"/><path d="M128 61L128 128L141 115ZM128 128L128 195L115 141ZM75 128L128 128L115 115Z" fill="#fff5bd"/><circle cx="128" cy="128" r="9" fill="#161d20" stroke="#fff0bd" stroke-width="3"/>'),
    "iron_heart": ('#99c7b6', '<path d="M128 184L78 129Q62 101 85 88Q107 75 128 100Q148 75 171 88Q194 101 178 129Z" fill="url(#metal)" stroke="#d9ead8" stroke-width="4"/><path d="M128 102L128 174M86 107L170 107M91 130L165 130M112 91L106 157M144 91L150 157" stroke="#243c40" stroke-width="7"/><circle cx="128" cy="128" r="15" fill="url(#gem)" stroke="#e7e6bd" stroke-width="3"/>'),
    "cursed_eye": ('#52c4ff', '<path d="M63 128Q128 53 193 128Q128 203 63 128Z" fill="url(#metal)" stroke="#e1e9d0" stroke-width="4"/><path d="M78 128Q128 78 178 128Q128 178 78 128Z" fill="#071524" stroke="#89d8ff" stroke-width="3"/><circle cx="128" cy="128" r="28" fill="url(#gem)" stroke="#d5f6ff" stroke-width="2"/><path d="M128 102Q141 128 128 154Q115 128 128 102Z" fill="#041220"/><circle cx="118" cy="117" r="7" fill="#e8fcff"/>'),
    "void_shard": ('#c68aff', '<path d="M129 62L165 103L153 158L123 194L91 145L98 98Z" fill="url(#gem)" stroke="#e5ccff" stroke-width="3"/><path d="M129 62L123 119L165 103M98 98L123 119L91 145M123 119L153 158L123 194Z" fill="#d3b6ff" fill-opacity=".25" stroke="#e5ccff" stroke-width="2"/><path d="M76 91L85 111L73 122L67 106ZM177 148L191 157L178 179L169 165Z" fill="url(#gem)" stroke="#d2b5f6"/>'),
    "ancient_tome": ('#71c5ed', '<path d="M87 75L163 71L181 173L99 186L79 169Z" fill="#40332c" stroke="#c8ae76" stroke-width="4"/><path d="M99 81L164 78L175 166L108 177Z" fill="url(#metal)" stroke="#d8c18e" stroke-width="2"/><path d="M84 82L99 81L108 177L95 176Z" fill="#12282b"/><path d="M137 99L158 128L141 155L121 131Z" fill="url(#gem)" stroke="#cbf3ff" stroke-width="2"/><path d="M110 91L158 87M116 165L162 157" stroke="#e1ca8c" stroke-width="3"/>'),
    "soul_lantern": ('#f1c965', '<path d="M115 80V68Q128 51 141 68V80M98 93L158 93L169 166L151 185L105 185L87 166Z" fill="#1b2524" stroke="url(#metal)" stroke-width="6"/><path d="M104 100L152 100L159 161L146 173L110 173L97 161Z" fill="url(#gem)"/><path d="M128 104Q103 136 123 161Q148 163 145 138Q133 145 128 104Z" fill="#fff6be"/><path d="M91 95L128 77L165 95M89 167L167 167M107 96L111 170M149 96L145 170" fill="none" stroke="#e0c68b" stroke-width="5"/>'),
    "mirror_shield": ('#c49cff', '<path d="M128 68L177 89L169 148Q160 173 128 192Q96 173 87 148L79 89Z" fill="url(#metal)" stroke="#eee3c9" stroke-width="4"/><path d="M128 83L163 99L156 146Q148 164 128 176Q108 164 100 146L93 99Z" fill="url(#gem)" stroke="#e7d7ff" stroke-width="2"/><path d="M128 87L108 156L138 112L150 142L159 101" fill="#fcf4ff" opacity=".3"/>'),
    "time_crystal": ('#7bdcf0', '<path d="M99 77L157 77L157 92L139 128L157 167L157 182L99 182L99 167L117 128L99 92Z" fill="#10262e" stroke="#bfe9e9" stroke-width="3"/><path d="M110 94L146 94L128 124ZM128 138L146 168L110 168Z" fill="url(#gem)"/><path d="M91 75L165 75M91 184L165 184M103 82L103 176M153 82L153 176" stroke="url(#metal)" stroke-width="7"/><path d="M128 122V144" stroke="#dcffff" stroke-width="3"/>'),
    "deaths_coin": ('#e2bb65', '<circle cx="128" cy="128" r="54" fill="url(#metal)" stroke="#ffe6a1" stroke-width="3"/><circle cx="128" cy="128" r="44" fill="#344039" stroke="#d9b972" stroke-width="2"/><path d="M106 134V111Q128 83 150 111V134L141 142V157H115V142Z" fill="url(#gem)" stroke="#ead49a" stroke-width="2"/><path d="M114 119L123 125L113 130ZM142 119L133 125L143 130ZM128 130L123 140H133Z" fill="#172827"/><path d="M122 146V157M134 146V157" stroke="#273b33" stroke-width="3"/>'),
    "phoenix_feather": ('#ffb34e', '<path d="M103 183Q77 132 116 90Q136 64 169 63Q188 112 146 151L113 179Z" fill="url(#gem)" stroke="#ffde91" stroke-width="3"/><path d="M96 197L159 80M109 173L101 143M120 150L98 124M131 129L110 103M138 116L160 109M121 151L153 141M111 171L136 165" fill="none" stroke="#ffe6ad" stroke-width="3"/><path d="M149 67L161 43L165 62M174 103L191 84L183 120" fill="#ffdc93"/>'),
    "shadow_cloak": ('#b198eb', '<path d="M128 68Q102 73 96 104L77 174L112 161L128 185L144 161L179 174L160 104Q154 73 128 68Z" fill="url(#gem)" stroke="#c5b4df" stroke-width="3"/><path d="M128 88Q104 97 105 125L128 146L151 125Q152 97 128 88Z" fill="#07151c" stroke="#9c91b6" stroke-width="2"/><path d="M115 116L124 120M132 120L141 116" stroke="#d4e8ff" stroke-width="3"/><path d="M96 168L104 135M160 168L152 135M128 150V176" stroke="#e1ceff" stroke-opacity=".5" stroke-width="2"/>'),
    "locked": ('#92859f', '<path d="M103 116V103Q103 75 128 75Q153 75 153 103V116" fill="none" stroke="url(#metal)" stroke-width="10"/><path d="M92 115L164 115L164 169L128 188L92 169Z" fill="url(#metal)" stroke="#b3a2bd" stroke-width="3"/><circle cx="128" cy="140" r="9" fill="#151b25"/><path d="M125 145L121 165H135L131 145" fill="#151b25"/>'),
}

def build(color, symbol):
    spikes = []
    for i in range(8):
        a = i * math.pi / 4
        points = []
        for radius, angle in [(107, a), (83, a - .085), (77, a), (83, a + .085)]:
            points.append(f'{128 + math.sin(angle)*radius:.2f},{128 - math.cos(angle)*radius:.2f}')
        spikes.append(f'<polygon points="{" ".join(points)}" fill="url(#metal)" stroke="#b5b8a2" stroke-width="1.5"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<defs><radialGradient id="aura"><stop stop-color="{color}" stop-opacity=".5"/><stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient><linearGradient id="metal" x2=".8" y2="1"><stop stop-color="#f8e6b9"/><stop offset=".25" stop-color="#7c8075"/><stop offset=".52" stop-color="#25343b"/><stop offset=".72" stop-color="#b7b49b"/><stop offset="1" stop-color="#273438"/></linearGradient><linearGradient id="gem" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#e3fcff"/><stop offset=".27" stop-color="{color}"/><stop offset=".65" stop-color="{color}"/><stop offset="1" stop-color="#08232f"/></linearGradient></defs>
<circle cx="128" cy="128" r="124" fill="url(#aura)"/>{''.join(spikes)}
<path d="M128 37L173 55L201 95L208 139L185 180L148 205L105 205L68 180L48 139L55 95L83 55Z" fill="#08161e" stroke="url(#metal)" stroke-width="8"/>
<circle cx="128" cy="128" r="78" fill="none" stroke="{color}" stroke-opacity=".55" stroke-width="2"/>
<circle cx="128" cy="128" r="84" fill="none" stroke="#e6d9b0" stroke-opacity=".4"/>
{symbol}
<path d="M66 71L69 80L78 83L69 86L66 95L63 86L54 83L63 80Z" fill="#edfcff" opacity=".9"/><path d="M193 152L195 159L202 161L195 163L193 170L191 163L184 161L191 159Z" fill="{color}"/>
</svg>'''

if __name__ == "__main__":
    TARGET.mkdir(parents=True, exist_ok=True)
    for name, (color, symbol) in ART.items():
        (TARGET / f"{name}.svg").write_text(build(color, symbol), encoding="utf-8")
    print(f"Generated {len(ART)} relic illustrations")

"""Split the existing vector portraits into reusable animation layers.
No new character illustration is introduced. Keep original paths and colors.
"""
from pathlib import Path
from copy import deepcopy
import re
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)
# Original path indices, retained in each layer's original drawing order.
PARTS = {
 'warrior': {'cape':[0,1], 'body':[5,6,7,8,9,10], 'left_arm':[11,12], 'right_arm':[13], 'weapon':[14,15], 'head':list(range(16,21)), 'legs':[3,4]},
 'mage': {'cape':[0,1,2], 'body':[6,7,8], 'left_arm':[9], 'right_arm':[10], 'weapon':[11,12,13], 'head':list(range(14,21)), 'legs':[4,5]},
 'ranger': {'cape':[0,1], 'body':[5,6,13,14,15,22], 'left_arm':[7], 'right_arm':[8], 'weapon':[9,10,11,12], 'head':list(range(16,22)), 'legs':[3,4]},
 'assassin': {'cape':[3,4], 'body':list(range(5,11)), 'head':list(range(14,19)), 'legs':[1,2], 'paired_arms':[11], 'paired_weapons':[12,13]},
 'druid': {'cape':[1,2], 'body':[3,8,9], 'head':list(range(12,18)), 'legs':[4,5], 'paired_arms':[6,7], 'weapon':[10,11]},
 'paladin': {'cape':[1,2], 'body':list(range(5,11)), 'left_arm':[11,12,13], 'weapon':[14,15,16,17], 'head':list(range(18,23)), 'legs':[3,4]}
}
def split_path(element):
    """Resolve relative subpath starts before separating left/right limbs."""
    tokens = re.findall(r'[a-zA-Z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?', element.attrib['d'])
    paths=[]; current=[]; x=y=0.0; sx=sy=0.0; i=0; command=''
    while i < len(tokens):
        if tokens[i].isalpha():
            command=tokens[i]; i+=1
            if command.lower()=='z':
                current.append(command); x,y=sx,sy; continue
            if command.lower()=='m':
                nx,ny=map(float,tokens[i:i+2]); i+=2
                x,y=(x+nx,y+ny) if command=='m' else (nx,ny)
                if current: paths.append(' '.join(current))
                current=['M',str(x),str(y), 'l' if command=='m' else 'L']; sx,sy=x,y
                command='l' if command=='m' else 'L'
                continue
            current.append(command)
        if command.lower()=='l':
            nx,ny=map(float,tokens[i:i+2]); current.extend(tokens[i:i+2]); i+=2
            x,y=(x+nx,y+ny) if command=='l' else (nx,ny)
        elif command.lower()=='h':
            nx=float(tokens[i]); current.append(tokens[i]); i+=1; x=x+nx if command=='h' else nx
        elif command.lower()=='v':
            ny=float(tokens[i]); current.append(tokens[i]); i+=1; y=y+ny if command=='v' else ny
        else: raise ValueError('Unsupported paired limb command: '+command)
    if current: paths.append(' '.join(current))
    assert len(paths)==2
    result=[]
    for path in paths:
        clone=deepcopy(element); clone.set('d',path); result.append(clone)
    return result
for owner, config in PARTS.items():
    source=ET.fromstring((ROOT/'assets/art/portraits'/f'{owner}.svg').read_text())
    children=list(source)
    assigned=[index for indices in config.values() for index in indices]
    expected=[index for index, element in enumerate(children) if element.tag.rsplit('}',1)[-1]!='ellipse']
    assert sorted(assigned)==expected, 'Every original character shape belongs to exactly one layer'
    layers={name:[deepcopy(children[i]) for i in indices] for name,indices in config.items() if name not in ('legs','paired_arms','paired_weapons')}
    for key,names in [('legs',('left_leg','right_leg')),('paired_arms',('left_arm','right_arm')),('paired_weapons',('left_weapon','weapon'))]:
        for index in config.get(key,[]):
            for name,element in zip(names,split_path(children[index])): layers.setdefault(name,[]).append(element)
    folder=ROOT/'assets/art/animations'/owner
    folder.mkdir(parents=True,exist_ok=True)
    for name in ['cape','left_leg','right_leg','body','left_arm','right_arm','left_weapon','weapon','head']:
        svg=ET.Element('{'+NS+'}svg',{'width':'480','height':'600','viewBox':'0 0 240 300'})
        svg.extend(layers.get(name,[]))
        ET.ElementTree(svg).write(folder/f'{name}.svg',encoding='utf-8',xml_declaration=False)
print('Generated 54 vector layers from six existing character portraits.')

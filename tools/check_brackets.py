from pathlib import Path
p=Path('lib/screens/patient/patient_home_screen.dart')
s=p.read_text(encoding='utf-8')
pairs={'(':')','{':'}','[':']'}
stack=[]
for i,ch in enumerate(s,1):
    if ch in pairs:
        stack.append((ch,i))
    elif ch in pairs.values():
        if not stack:
            # compute line/col
            line = s.count('\n',0,i)+1
            col = i - s.rfind('\n',0,i)
            print(f'Unmatched closing {ch} at char {i} (line {line}, col {col})')
            break
        last,loc=stack.pop()
        if pairs[last]!=ch:
            line1 = s.count('\n',0,loc)+1
            col1 = loc - s.rfind('\n',0,loc)
            line2 = s.count('\n',0,i)+1
            col2 = i - s.rfind('\n',0,i)
            print(f'Mismatched {last} at char {loc} (line {line1}, col {col1}) with {ch} at char {i} (line {line2}, col {col2})')
            break
else:
    if stack:
        print('Unclosed at end:', stack[-1])
    else:
        print('All matched')

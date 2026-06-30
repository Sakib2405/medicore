from pathlib import Path

s=Path('lib/screens/patient/patient_home_screen.dart').read_text(encoding='utf-8')
loc=54748
# find line start
start=s.rfind('\n',0,loc)+1
end=s.find('\n',loc)
print('LINE CONTEXT:')
print(s[start:end])
print('around...')
print(s[loc-40:loc+40])

start_pos = s.find('return RefreshIndicator(')
end_pos = s.find('\n  Widget _buildPatientIdCard', start_pos)
snippet = s[start_pos:end_pos]
print('\n--- SNIPPET ---\n')
print(snippet[:1000])

stack=[]
pairs={'(':')','{':'}','[':']'}
for i,ch in enumerate(snippet,1):
	if ch in pairs:
		stack.append((ch,i))
	elif ch in pairs.values():
		if not stack:
			print('Unmatched closing',ch,'at',i)
			break
		last,loc2=stack.pop()
		if pairs[last]!=ch:
			print('MISMATCH',last,loc2,'with',ch,i)
			# print surrounding context
			start_ctx = max(0, i-40)
			end_ctx = min(len(snippet), i+40)
			print('\nContext around mismatch:\n')
			print(snippet[start_ctx:end_ctx])
			break
else:
	if stack:
		last,loc2=stack[-1]
		print('Unclosed at end:',last,loc2)
	else:
		print('All matched in snippet')

import os
from plistlib import dump

# Add in the cards
with open("cardlist.txt","r") as f:
	data = f.readlines()

cards = {}
for line in data:
	if line[0] == "#" or line == "\n":
		continue
	tokens = line.split(" ")
	if tokens[2] not in cards:
		cards[tokens[2]] = []
	cards[tokens[2]].append({"name": tokens[0], "value":tokens[1], "flavor":tokens[3]})

if os.path.exists("cards.plist"):
	os.remove("cards.plist")

with open("cards.plist","wb+") as c:
	dump(cards,c)
	print("Successfully updated Cards!")

# Add in the combos
with open("combos.txt", "r") as f:
	data = f.readlines()

combos = {}
for line in data:
	if line[0] == "#" or line == "\n":
		continue
	tokens = line.split(" ")
	name = tokens[0]
	multiplier = float(tokens[1])
	newreqs = []
	for req in tokens[2:]:
		newreqs.append(req.replace("\n",""))
	combos[tokens[0]] = {"multiplier": multiplier, "reqs":newreqs}

if os.path.exists("Slamwich/Slamwich/combos.plist"):
	os.remove("Slamwich/Slamwich/combos.plist")

with open("Slamwich/Slamwich/combos.plist", "wb+") as c:
	dump(combos, c)
	print("Successfully updated Combos!")

print("-------------")

# Check for combo-less cards
for (_, cardList) in cards.items():
	for card in cardList:
		name = card["name"]
		inflag = False
		for (comboName, combo) in combos.items():
			if name in combo["reqs"]:
				inflag = True
				break
		if not inflag:
			print(f"{name}\t has no direct combos")
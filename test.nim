import src/engine
import std/json

echo Rarity(1)

let items: seq[Item] = genLoot(
    roll=10,
    isNatTwenty=false,
    loc="underdark",
    allItems=getAllItems(@[])
)

echo pretty(%items)

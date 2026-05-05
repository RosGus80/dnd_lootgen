import src/engine
import strutils


let seq: seq[string] = @["some", "strings"]

let input = stdin.readline()
try:
    echo $Rarity(input.parseInt())
except Exception as e:
    echo "Exception type: ", e.name
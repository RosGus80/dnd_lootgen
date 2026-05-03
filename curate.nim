import json, os, strutils, sequtils, options
import src/engine

# Helpers

proc saveJson(path: string, data: JsonNode) =
    writeFile(path, $data)

proc getNextId(custom: JsonNode): uint =
    var maxId: uint = 0
    for item in custom:
        if item.hasKey("id"):
            maxId = max(maxId, item["id"].getInt.uint)
    return maxId + 1

proc itemExists(custom: JsonNode, name: string): bool =
    for item in custom:
        if item["name"].getStr.toLowerAscii == name.toLowerAscii:
            return true
    return false

proc chooseLocation(): seq[Location] =
    echo "\nChoose location(s) (comma or space separated):"
    for i, loc in allLocationsSeq:
        echo i, ": ", loc

    stdout.write("> ")
    let input = stdin.readLine()

    let parts = input.replace(",", " ").splitWhitespace()

    result = @[]

    for p in parts:
        if p.len == 0: continue

        try:
            let idx = parseInt(p)
            if idx >= 0 and idx < allLocationsSeq.len:
                result.add(allLocationsSeq[idx])
            else:
                echo "Skipping invalid index: ", idx
        except ValueError:
            echo "Skipping invalid input: ", p

    if result.len == 0:
        echo "No valid selections, defaulting to 'any'"
        return @["all"]

proc chooseRarity(price: int, defaultRarity: Rarity): Rarity =
    echo "\nChoose rarity:"
    
    if price > 0:
        echo "0: auto (from price)"
    else:
        echo "0: " & $defaultRarity & "(from default)"
    

    for i in 0..Rarity.high.ord:
        let r = Rarity(i)
        echo i+1, ": ", $r

    stdout.write("> ")
    let input = stdin.readLine().strip

    if input.len == 0:
        if price > 0:
            return rarityFromPrice(price)
        else:
            return defaultRarity

    let choice =
        try:
            parseInt(input)
        except ValueError:
            -1

    if choice == 0:
        if price > 0:
            return rarityFromPrice(price)
        else:
            return defaultRarity
    elif choice-1 in 0..Rarity.high.ord:
        return Rarity(choice-1)
    else:
        echo "Invalid choice, using auto"
        if price > 0:
            return rarityFromPrice(price)
        else:
            return defaultRarity


proc parseRaritySafe(s: string): Rarity =
    let normalized = s.capitalizeAscii
    
    if normalized == "Very Rare":
        return parseEnum[Rarity]("Epic")

    try: 
        return parseEnum[Rarity](normalized)
    except ValueError:
        return parseEnum[Rarity]("Common")


proc createCustomItem(id: uint, raw: JsonNode): JsonNode =
    let name = raw["name"].getStr
    let desc =
        if raw.hasKey("description"):
            raw["description"].getStr
        elif raw.hasKey("desc"):
            raw["desc"].getStr
        else:
            ""
    let price = 
        if raw.hasKey("cost"):
            raw["cost"]["quantity"].getInt
        else:
            0

    let rarity = 
        if raw.hasKey("rarity") and raw["rarity"].hasKey("name"):
            parseRaritySafe(raw["rarity"]["name"].getStr)
        else:
            rarityFromPrice(price)

    echo "\n--- New Item ---"
    echo "Name: ", name
    echo "Description: ", desc
    echo "Price: ", price, " gp"
    echo "Rarity: ", rarity

    let locations = chooseLocation()
    let curatedRarity = chooseRarity(price, rarity)

    result = %*{
        "id": id,
        "name": name,
        "description": desc,
        "gpCost": price,
        "rarity": $curatedRarity,
        "locations": locations
    }

# Main 

let rawDir = "db/raw"
let customDir = "db/core"

let targetFile =
    if paramCount() > 0:
        paramStr(1)
    else:
        ""

if targetFile.len > 0:
  let file = rawDir / targetFile
  let fileName = splitFile(file).name
  let customPath = customDir / (fileName & ".json")

  let rawData = loadJsonArray(file)
  var customData = loadJsonArray(customPath)

  var nextId = getNextId(customData)

  for rawItem in rawData:
    let name = rawItem["name"].getStr

    if not itemExists(customData, name):
      let newItem = createCustomItem(nextId, rawItem)
      customData.add(newItem)
      inc nextId

      saveJson(customPath, customData)

  saveJson(customPath, customData)

else:
  for file in walkFiles(rawDir / "*.json"):
    let fileName = splitFile(file).name
    let customPath = customDir / (fileName & ".json")

    let rawData = loadJsonArray(file)
    var customData = loadJsonArray(customPath)

    var nextId = getNextId(customData)

    for rawItem in rawData:
      let name = rawItem["name"].getStr

      if not itemExists(customData, name):
        let newItem = createCustomItem(nextId, rawItem)
        customData.add(newItem)
        inc nextId

        saveJson(customPath, customData)

    saveJson(customPath, customData)